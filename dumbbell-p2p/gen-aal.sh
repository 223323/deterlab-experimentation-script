#!/usr/bin/env bash
[ $# == 1 ] || exit

. experiment.sh

cat > $1 <<EOF
## THIS FILE IS GENERATED, DON'T EDIT
## The mapping from the AAL procedure to the experiment apparatus

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
    execargs: {servers: *slist, interval: '0.08', sizes: 'minmax(1000,50000)'}
    # execargs: {servers: *slist, interval: '0.8', sizes: '1000'}
    
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
    execargs: { cmd: '$datadir/syn --attack-ips 10.0.xx.xxx --ip 10.0.8.1 --port 80 --threads 1 --duration 1 --attack_sleep 10000', mark_time: 1 }

streamstarts: [ serverstream, clientstream, cleanupstream, changestream, attackstream_start ]

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
        agent: attack_agent
        method: startExperiment
        args: {}
        
      - type: event
        agent: monitor_agent
        method: startCollection
        # args: { expression: '$tcpdump_expr', tcpdump_args: '-z gzip -C 600' }
        args: { expression: '', tcpdump_args: '-z gzip -C 600' }
        
      - type: event
        agent: client_agent
        trigger: clientStarted
        method: startClient
        args: {}
        
      - type: trigger
        triggers: [ { timeout: 30000 } ]

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
        triggers: [ { event: clientStarted } ] 
        
      - type: trigger
        triggers: [ { timeout: 5000 } ]
        
      - type: trigger
        triggers: [ { timeout: 0, target: 'attackstream' } ]
        
  attackstream:
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 6000 } ]
        
      - type: event
        agent: attack_agent
        method: startCmd
        args: {}
        
      - type: trigger
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 2000 } ]
        
      - type: event
        agent: attack_agent
        method: stopCmd
        args: {}
        
      - type: trigger
        triggers: [ { timeout: 0, target: 'attackstream' } ]
        
        
  changestream:
      - type: event
        agent: client_agent
        method: changeTraffic
        args: { stepsize: 1000 }
    
      - type: trigger
        triggers: [ { timeout: 1500 } ]
        
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
