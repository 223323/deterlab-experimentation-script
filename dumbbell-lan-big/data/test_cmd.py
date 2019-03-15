import time
import datetime
import signal

running=True
def on_exit(a,b):
	global running
	running=False
	
signal.signal(signal.SIGINT, on_exit)
signal.signal(signal.SIGTERM, on_exit)
	

# f.write('begin\n')
while running:
	# print( 'now: ' , time.strftime('%X %x %Z'))
	with open('/tmp/test_cmd.log','a+') as f:
		f.write(time.strftime('%X %x %Z')+'\n')
	time.sleep(1)




