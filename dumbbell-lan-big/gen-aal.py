import random
clients=repl('$clients').split(',')
monitor=repl('$monitor').split(',')
servers=repl('$servers').split(',')
attackers=repl('$attackers').split(',')

# GROUPS
client_group = groups.new('client_group', clients)
monitor_group = groups.new('monitor_group', monitor)
server_group = groups.new('server_group', servers)
attack_group = groups.new('attack_group', attackers)

# AGENTS
client_agent = agents.new('client_agent', client_group, '$mods/http_client/', 
	{'servers': servers, 'interval': 'expo(1/15.0)', 'sizes': 'pareto(1.2)*2000'})
monitor_agent = agents.new('monitor_agent', monitor_group, '$mods/tcpdump/tcpdump.tar.gz')
server_agent = agents.new('server_agent', server_group, '$mods/apache/apache.tar.gz')
collect_agent = agents.new('collect_agent', group=monitor_group, path='$datadir/cmd.tgz',
	execargs={'cmd': './collect.sh', 'cwd':'$expdir'})
attack_agent = agents.new('attack_agent', group=attack_group, path='$datadir/cmd.tgz',
	execargs={'cmd': '$datadir/syn --attack-ips 10.0.xxx.xxx --ip 10.0.1.3 '+
		'--port 80 --threads 1 --duration 30 --attack-sleep 1000', 'mark_time': 1 })

def on_off_attacks(lst):
	for (a,b) in lst:
		attack_agent('startCmd')
		trigger([[a], ['clientStopped', 'stopattack']])
		attack_agent('stopCmd')
		trigger([[b], ['clientStopped', 'stopattack']])
	with stream('stopattack'):
		attack_agent('stopCmd')
	
# STREAMS
with stream('serverstream',True):
	server_agent('startServer', trigger='serverStarted')
	trigger('clientStopped')
	server_agent('stopServer', trigger='serverStopped')
	
with stream('clientstream',True):
	trigger('serverStarted')
	collect_agent('execute', {'args':'preprocess'}).wait()
	
	monitor_agent('startCollection', 
		{ 'expression': '$tcpdump_expr', 'tcpdump_args': '-z gzip -C 200' }, trigger='start_attack')
	attack_agent('startExperiment')
	
	client_agent('startClient', trigger='clientStarted')
	trigger(500)
	client_agent('stopClient', trigger='clientStopped')
	
	monitor_agent('stopCollection').wait()
	
	collect_agent('execute', {'args':'postprocess'})
	trigger(0,'cleanupstream')

with stream('attackstream_start',True):
	trigger('start_attack')
	trigger(8, 'attackstream2')

	with stream('attackstream'):
		on_off_attacks( [(5,25), (5,50)] )
		loop()
	
	with stream('attackstream2'):
		on_off_attacks( [(15,80), (15, 60), (3, 50), (15,50)] )
		loop()

with stream('cleanupstream'):
	trigger('serverStopped','exit')

with stream('changestream', True):
	trigger('clientStarted')
	for i in range(10):
		client_agent('changeTraffic', args={'stepsize':random.randint(100,1000)})
		trigger(random.randint(1,10))
	loop()


