#!/usr/bin/env python 

import logging
import os
import signal
import sys
import time
# import json
import subprocess
from magi.testbed import testbed
from magi.util.agent import DispatchAgent, agentmethod
from magi.util.processAgent import initializeProcessAgent
import magi.util.execl as execl

class cmd_agent(DispatchAgent):
	"""
	starts/stops command
	"""
	def __init__(self):
		DispatchAgent.__init__(self)
		self.pids = []
		# 'Attack Source'
		self.maxCmds=1
		self.cmd = ''
		self.log = logging.getLogger(__name__)
		self.ofs = time.time()
		self.times = {'start':[], 'end':[]}
		self.mark_time = 0

	@agentmethod() 
	def execute(self, msg, args=None):
		cmd = [str(self.cmd)]
		if args: cmd.append(args)
		self.log.info('Running cmd: %s' % cmd)
		output = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()[0]
		self.log.info('Output: ' + output)
		return True
	
	@agentmethod()
	def startCmd(self, msg, args=None):
		cmd=self.cmd
		if args: cmd += ' ' + args
		if len(self.pids) < self.maxCmds:
			self.pids.append(execl.spawn(cmd, self.log, close_fds=True, shell=False))
			self.log.info('start cmd: ' + cmd + ' PID: ' + str(self.pids[-1]))
		if self.mark_time and self.pids:
			self.times['start'].append( time.time()-self.ofs )
		return True

	@agentmethod()
	def startExperiment(self, msg):
		self.ofs = time.time()
		
	@agentmethod()
	def stopCmd(self, msg):
		self.log.info('stopCmd() called, PIDS ' + str(self.pids))
		left=[]
		for pid in self.pids:
			self.log.info('stopCmd() killing %s' % pid)
			try:
				# os.kill(pid, signal.SIGTERM)
				# time.sleep(0.5)
				os.kill(pid, signal.SIGKILL)
			except:
				self.log.info('stopCmd() killing %s FAILED' % pid)
				left.append(pid)
				raise
				
		if self.mark_time and self.pids:
			self.times['end'].append( time.time()-self.ofs )
		if left:
			self.log.info('left with exception: ' + str(left))
			self.pids = left
		else:
			self.pids = []
		return True
	
	@agentmethod()
	def stop(self, msg):
		self.stopCmd(msg)
		DispatchAgent.stop(self, msg)
		
		if self.mark_time:
			# with open('/tmp/cmd_agent.json','w') as f:
				# json.dump( self.times, f, indent=4 )
				# f.write('\n')
			with open('/tmp/output/attack-times.csv','w') as f:
				try:
					f.write(','.join([str(a) for a in self.times['start']]))
					f.write('\n')
					f.write(','.join([str(a) for a in self.times['end']]))
					f.write('\n')
				except Exception as e:
					f.write('some exception: ' + str(e))

	@agentmethod()
	def confirmConfiguration(self):
		return True
	
def getAgent(**kwargs):
	agent = cmd_agent()
	agent.setConfiguration(None, **kwargs)
	return agent

if __name__ == "__main__":
	agent = cmd_agent()
	kwargs = initializeProcessAgent(agent, sys.argv)
	agent.setConfiguration(None, **kwargs)
	agent.run()

