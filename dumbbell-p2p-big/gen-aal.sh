#!/usr/bin/env bash
[ $# == 1 ] || exit
. experiment.sh

cat > $1 <<EOF
groups:
  client_group: &clist [$clients]
  monitor_group: [$monitor]
  server_group: &slist [$servers]
  attack_group: [$attackers]
  
## The agent implementation and addressing information
agents:
  client_agent:
    group: client_group
    path: $mods/http_client/http_client.tar.gz
    execargs: {servers: *slist, interval: 'minmax(3,10)', sizes: 'minmax(500,1000)'}
    # execargs: {servers: *slist, interval: 'expo(1/15.0)', sizes: 'pareto(1.2)'}
    
  monitor_agent:
    group: monitor_group
    path: $mods/tcpdump/tcpdump.tar.gz
    # path: $datadir/cmd.tgz
    execargs: { }

  server_agent:
    group: server_group
    path: $mods/apache/apache.tar.gz
    execargs: []
    
  collect_agent:
    group: monitor_group
    path: $datadir/cmd.tgz
    execargs: {cmd: '$expdir/collect.sh'}
    
  attack_agent:
    group: attack_group
    path: $datadir/cmd.tgz
    execargs: { cmd: '$datadir/syn --attack-ips 10.0.xxx.xxx --ip 10.0.0.1 --port 80 --threads 1 --duration 30 --attack-sleep 500', mark_time: 1 }

streamstarts: [ serverstream, clientstream, cleanupstream, attackstream_start ]

eventstreams:

  serverstream:
      - type: event
        agent: server_agent
        method: startServer
        trigger: serverStarted
        args: {}

      - type: trigger
        triggers: [ { event: clientStopped} ] 

      - type: event
        agent: server_agent
        method: stopServer 
        trigger: serverStopped 
        args: {} 

  clientstream:
      - type: trigger
        triggers: [ { event: serverStarted } ] 
        
      - type: event
        agent: collect_agent
        method: execute
        trigger: cleaned_up
        args: { args: 'cleanup' }
        
      - type: trigger
        triggers: [ { event: cleaned_up } ]
        
      - type: event
        agent: monitor_agent
        trigger: start_attack
        method: startCollection
        args: { expression: '$tcpdump_expr', tcpdump_args: '-z gzip -C 200' }
        
      - type: event
        agent: attack_agent
        method: startExperiment
        args: {}
        
      - type: event
        agent: client_agent 
        method: startClient
        args: {}

      - type: trigger
        triggers: [ { timeout: 500000 } ]

      - type: event
        agent: client_agent
        method: stopClient
        trigger: clientStopped 
        args: {}
        
      - type: event
        agent: monitor_agent
        method: stopCollection
        trigger: pcap_done
        args: {}
        
      - type: trigger
        triggers: [ { event: pcap_done } ]
      
      - type: event
        agent: collect_agent
        method: execute
        trigger: collection_done
        args: {}
  
  attackstream_start:
      - type: trigger
        triggers: [ { event: start_attack } ] 
        
      - type: trigger
        triggers: [ { timeout: 150000 } ]
        
      - type: trigger
        triggers: [ { timeout: 0, target: 'attackstream2' } ]
        
        
  attackstream:
        
      - type: event
        agent: attack_agent
        method: startCmd
        args: {}
        
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 5000 } ]
        
      - type: event
        agent: attack_agent
        method: stopCmd
        args: {}
        
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 120000 } ]
      
      - type: trigger
        triggers: [ { timeout: 0, target: 'attackstream' } ]
        
  attackstream3:
        
      - type: event
        agent: attack_agent
        method: startCmd
        args: {}
        
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 8000 } ]
        
      - type: event
        agent: attack_agent
        method: stopCmd
        args: {}
        
  attackstream2:
        
      - type: event
        agent: attack_agent
        method: startCmd
        args: {}
        
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 15000 } ]
        
      - type: event
        agent: attack_agent
        method: stopCmd
        args: {}
   
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 80000 } ]
       
      - type: event
        agent: attack_agent
        method: startCmd
        args: {}
        
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 15000 } ]
        
      - type: event
        agent: attack_agent
        method: stopCmd
        args: {}
        
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 120000 } ]
        
      - type: event
        agent: attack_agent
        method: startCmd
        args: {}
        
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 3000 } ]
        
      - type: event
        agent: attack_agent
        method: stopCmd
        args: {}
        
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 120000 } ]
        
      - type: event
        agent: attack_agent
        method: startCmd
        args: {}
        
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 30000 } ]
        
      - type: event
        agent: attack_agent
        method: stopCmd
        args: {}
        
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 120000 } ]
        
  changestream:
      - type: event
        agent: client_agent
        method: changeTraffic
        args: { stepsize: 1000 }
    
      - type: trigger
        triggers: [ { timeout: 15000 } ]
        
      - type: trigger
        triggers: [ { target: 'changestream' } ]
        
  cleanupstream:
      - type: event
        agent: attack_agent
        method: stopCmd
        args: {}
        
      - type: trigger
        triggers: [ {event: collection_done, target: exit}, {event: serverStopped, target: exit} ] 


################################################
EOF
