
import logging
import os
import signal
import sys
import subprocess
import json

class cmd_agent():
	"""
	Provides an interface to the flooder utility. 
	"""
	def __init__(self):
		"""Init base class; install required software; setup initial configuration."""
		self.pids = []
		self.cmd = None
		self.log = logging.getLogger(__name__)
		self.ofs = time.time()
		self.log2 = []

	def startCmd(self, msg):
		proc = subprocess.Popen([self.cmd], close_fds=True, stdout=None, shell=True)
		self.pids.append(proc.pid)
		self.log2.append( {'start time': time.time()-self.ofs } )
		return True

	def stopCmd(self, msg):
		self.log.debug('stopFlood() called with msg: %s' % msg)
		for pid in self.pids:
			self.log.debug('stopFlood() killing %s' % pid)
			os.kill(pid, signal.SIGTERM)

		self.pids = []
		self.log2.append( {'end time': time.time()-self.ofs } )
		return True

	def stop(self, msg):
		self.stopCmd(msg)
		# DispatchAgent.stop(self, msg)
		with open('/tmp/cmd_agent.json','w') as f:
			# f.write('begin')
			json.dump( self.log2, f, indent=4 )
			f.write('\n')


	def confirmConfiguration(self):
		return True

import time
if __name__ == "__main__":
	agent = cmd_agent()
	agent.cmd='./test_looping_cmd.py'
	agent.startCmd('')
	time.sleep(10)
	# agent.stopCmd('l')
	agent.stop('')
	print('stopped')
	time.sleep(10)
