#!/bin/bash
# initial system-analysis script
 
# make sure we're root
if [ "$EUID" -ne 0 ]
    then echo "Please execute this script as the root user."
    exit
fi
 
# make audit directory
mkdir -p /audit
 
# host info
lspci > /audit/lspci.txt
 
# cpu info
cpuCount=`nproc`
cpuInfo=`vmstat`
cat /proc/cpuinfo > /audit/cpuVerbose.txt
 
# memory
pageSize=`getconf PAGESIZE`
freeMem=`cat /proc/meminfo | awk 'NR==2'`
detailedMem=`free -m`
topMemHogs=`top -b -n 5 -o %MEM | head -n 12`
 
# file system
diskUsage=`df -hm`
blockDevices=`lsblk`
blockSize=`stat --printf='%s' -f .`
minorFaults=`ps -o min_flt $controllerProcess | awk 'NR==2'`
majorFaults=`ps -o maj_flt $controllerProcess | awk 'NR==2'`
mountDetails=`mount`
 
# database
mysqldProcess=`pgrep -f 'mysqld[^_]'`
mysqldStatus=`cat /proc/$mysqldProcess/status`
cat /proc/$mysqldProcess/limits > /audit/mysqldLimits.txt
 
# networking
ifConfig=`ifconfig`
myHost=`hostname`
if [ -z type dig &> /dev/null ]; then
    myDNS=`nslookup 127.0.0.1 | grep Server`
else
    myDNS=`dig +noquestion +nocomments +nocmd +nostats $myHost. | awk 'END{print;}'`
fi
 
# output to master audit file
if [[ -s /audit/lspci.txt ]]; then
    echo "Host environment:" > /audit/keyhole.log
    cat /audit/lspci.txt | while read line; do echo "$line" >> /audit/keyhole.log; done
else
    echo "Host environment: information not available." > /audit/keyhole.log
fi
echo >> /audit/keyhole.log
echo "CPU Diagnostics:" >> /audit/keyhole.log
if [ -z "$cpuCount" ]; then
    echo "Cores: CPU count unavailable." >> /audit/keyhole.log
else
    echo "Cores: "$cpuCount  >> /audit/keyhole.log
fi
if [ -z "$cpuInfo" ]; then
    echo "CPU usage stats unavailable." >> /audit/keyhole.log
else
    echo -e "$cpuInfo" >> /audit/keyhole.log
fi
echo >> /audit/keyhole.log
echo "Memory Diagnostics:" >> /audit/keyhole.log
echo "Page Size: "$pageSize >> /audit/keyhole.log
if [ -z "$freeMem" ]; then
    echo "Free memory stats unavailable." >> /audit/keyhole.log
else
    echo -e "$freeMem" > /audit/keyhole.log
fi
if [ -z "$detailedMem" ]; then
    echo "Detailed memory stats unavailable." >> /audit/keyhole.log
else
    echo -e "$detailedMem" >> /audit/keyhole.log
fi
if [ -z "$topMemHogs" ]; then
    echo -e "Top 5 Memory Users query failed." >> /audit/keyhole.log
else
    echo -e "Top 5 Memory Users:\n$topMemHogs" >> /audit/keyhole.log
fi
echo >> /audit/keyhole.log
echo "Disk Diagnostics:" >> /audit/keyhole.log
if [ -z "$diskUsage" ]; then
    echo -e "Disk usage stats unavailable" >> /audit/keyhole.log
else
    echo -e "Disk Usage:\n$diskUsage" >> /audit/keyhole.log
fi
if [ -z "$blockDevices" ]; then
    echo -e "Block Device details unavailable." >> /audit/keyhole.log
else
    echo -e "Block Devices:\n$blockDevices" >> /audit/keyhole.log
fi
if [ -z "$blockSize" ]; then
    echo -e "Block size details unavailable."
else
    echo "Block Size: "$blockSize >> /audit/keyhole.log
fi
if [ -z "$minorFaults" ]; then
    echo -e "Minor fault details unavailable." >> /audit/keyhole.log
else
    echo "Minor File System Faults: "$minorFaults >> /audit/keyhole.log
fi
if [ -z "$majorFaults" ]; then
    echo -e "Major fault details unavailable." >> /audit/keyhole.log
else
    echo "Major File System Faults: "$majorFaults >> /audit/keyhole.log
fi
if [ -z "$mountDetails" ]; then
    echo -e "Mount details unavailable." >> /audit/keyhole.log
else
    echo -e "Mount Details:\n$mountDetails" >> /audit/keyhole.log
fi
echo >> /audit/keyhole.log
echo "Network Diagnostics:" >> /audit/keyhole.log
if [ -z "$myDNS" ]; then
    echo -e "DNS details unavailable." >> /audit/keyhole.log
else
    echo -e "$myDNS" >> /audit/keyhole.log
fi
if [ -z "$ifConfig" ]; then
    echo -e "Network configuration unavailable." >> /audit/keyhole.log
else
    echo -e "$ifConfig" >> /audit/keyhole.log
fi
echo >> /audit/keyhole.log
echo "Database Diagnostics:" >> /audit/keyhole.log
if [ -z "$mysqldProcess" ]; then
    echo "MySql Process: "$mysqldProcess >> /audit/keyhole.log
fi
echo "mysqld Limits:" >> /audit/keyhole.log
if [[ -s /audit/mysqldLimits.txt ]]; then
    cat /audit/mysqldLimits.txt | while read line; do echo "$line" >> /audit/keyhole.log; done
else
    echo -e "MySQL limits unavailable." >> /audit/keyhole.log
fi
echo "Verbose CPU details:" >> /audit/keyhole.log
if [[ -s /audit/cpuVerbose.txt ]]; then
     cat /audit/cpuVerbose.txt | while read line; do echo "$line" >> /audit/keyhole.log; done
else
    echo -e "Verbose CPU info unavailable." >> /audit/keyhole.log
fi
 
# clean up after myself
 
rm -f /audit/mysqldLimits.txt
rm -f /audit/cpuVerbose.txt
rm -f /audit/lspci.txt
