#!/usr/bin/env bash
[ $# == 1 ] || exit

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
    # execargs: {servers: *slist, interval: 'minmax(1,10)', sizes: 'minmax(5000,100000)'}
    execargs: {servers: *slist, interval: 'expo(1/15.0)', sizes: 'pareto(1.2)*2000'}
    
  monitor_agent:
    group: monitor_group
    path: $mods/tcpdump/tcpdump.tar.gz
    execargs: { }

  server_agent:
    group: server_group
    path: $mods/apache/apache.tar.gz
    execargs: []
    
  collect_agent:
    group: monitor_group
    path: $datadir/cmd.tgz
    execargs: {cmd: $expdir/collect.sh, cwd: $expdir}
    
  attack_agent:
    group: attack_group
    path: $datadir/cmd.tgz
    execargs: { cmd: '$datadir/syn --attack-ips 10.0.xxx.xxx --ip 10.0.1.3 --port 80 --threads 1 --duration 30 --attack-sleep 1000', mark_time: 1 }

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
        args: {args: preprocess}
        
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
        args: {args: postprocess}
  
  attackstream_start:
      - type: trigger
        triggers: [ { event: start_attack } ] 
        
      - type: trigger
        triggers: [ { timeout: 80000 } ]
        
      - type: trigger
        triggers: [ { timeout: 0, target: 'attackstream' } ]
        
        
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
        triggers: [ { event: clientStopped, target: cleanupstream }, { timeout: 25000 } ]
      
      #######
      
      - type: trigger
        triggers: [ { target: 'attackstream' } ]
        
  changestream:
      - type: event
        agent: client_agent
        method: changeTraffic
        args: { stepsize: 1000 }
    
      - type: trigger
        triggers: [ { timeout: 15000, target: 'changestream' } ]
        
  cleanupstream:
      - type: event
        agent: attack_agent
        method: stopCmd
        args: {}
        
      - type: trigger
        triggers: [ {event: collection_done, target: exit}, {event: serverStopped, target: exit} ] 


################################################
EOF
