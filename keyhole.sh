#!/bin/bash
# bash system-analysis script; writes output to a directory called keyhole
 
# make sure we're root
if [ "$EUID" -ne 0 ]
    then echo "Please execute this script as the root user."
    exit
fi
 
# make keyhole directory
mkdir -p /keyhole
 
# host info
lspci > /keyhole/lspci.txt
 
# cpu info
cpuCount=`nproc`
cpuInfo=`vmstat`
cat /proc/cpuinfo > /keyhole/cpuVerbose.txt
 
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
cat /proc/$mysqldProcess/limits > /keyhole/mysqldLimits.txt
# we should write mongodb in here as well
 
# networking
ifConfig=`ifconfig`
myHost=`hostname`
if [ -z type dig &> /dev/null ]; then
    myDNS=`nslookup 127.0.0.1 | grep Server`
else
    myDNS=`dig +noquestion +nocomments +nocmd +nostats $myHost. | awk 'END{print;}'`
fi
 
# output to master keyhole file
if [[ -s /keyhole/lspci.txt ]]; then
    echo "Host environment:" > /keyhole/keyhole.log
    cat /keyhole/lspci.txt | while read line; do echo "$line" >> /keyhole/keyhole.log; done
else
    echo "Host environment: information not available." > /keyhole/keyhole.log
fi
echo >> /keyhole/keyhole.log
echo "CPU Diagnostics:" >> /keyhole/keyhole.log
if [ -z "$cpuCount" ]; then
    echo "Cores: CPU count unavailable." >> /keyhole/keyhole.log
else
    echo "Cores: "$cpuCount  >> /keyhole/keyhole.log
fi
if [ -z "$cpuInfo" ]; then
    echo "CPU usage stats unavailable." >> /keyhole/keyhole.log
else
    echo -e "$cpuInfo" >> /keyhole/keyhole.log
fi
echo >> /keyhole/keyhole.log
echo "Memory Diagnostics:" >> /keyhole/keyhole.log
echo "Page Size: "$pageSize >> /keyhole/keyhole.log
if [ -z "$freeMem" ]; then
    echo "Free memory stats unavailable." >> /keyhole/keyhole.log
else
    echo -e "$freeMem" > /keyhole/keyhole.log
fi
if [ -z "$detailedMem" ]; then
    echo "Detailed memory stats unavailable." >> /keyhole/keyhole.log
else
    echo -e "$detailedMem" >> /keyhole/keyhole.log
fi
if [ -z "$topMemHogs" ]; then
    echo -e "Top 5 Memory Users query failed." >> /keyhole/keyhole.log
else
    echo -e "Top 5 Memory Users:\n$topMemHogs" >> /keyhole/keyhole.log
fi
echo >> /keyhole/keyhole.log
echo "Disk Diagnostics:" >> /keyhole/keyhole.log
if [ -z "$diskUsage" ]; then
    echo -e "Disk usage stats unavailable" >> /keyhole/keyhole.log
else
    echo -e "Disk Usage:\n$diskUsage" >> /keyhole/keyhole.log
fi
if [ -z "$blockDevices" ]; then
    echo -e "Block Device details unavailable." >> /keyhole/keyhole.log
else
    echo -e "Block Devices:\n$blockDevices" >> /keyhole/keyhole.log
fi
if [ -z "$blockSize" ]; then
    echo -e "Block size details unavailable."
else
    echo "Block Size: "$blockSize >> /keyhole/keyhole.log
fi
if [ -z "$minorFaults" ]; then
    echo -e "Minor fault details unavailable." >> /keyhole/keyhole.log
else
    echo "Minor File System Faults: "$minorFaults >> /keyhole/keyhole.log
fi
if [ -z "$majorFaults" ]; then
    echo -e "Major fault details unavailable." >> /keyhole/keyhole.log
else
    echo "Major File System Faults: "$majorFaults >> /keyhole/keyhole.log
fi
if [ -z "$mountDetails" ]; then
    echo -e "Mount details unavailable." >> /keyhole/keyhole.log
else
    echo -e "Mount Details:\n$mountDetails" >> /keyhole/keyhole.log
fi
echo >> /keyhole/keyhole.log
echo "Network Diagnostics:" >> /keyhole/keyhole.log
if [ -z "$myDNS" ]; then
    echo -e "DNS details unavailable." >> /keyhole/keyhole.log
else
    echo -e "$myDNS" >> /keyhole/keyhole.log
fi
if [ -z "$ifConfig" ]; then
    echo -e "Network configuration unavailable." >> /keyhole/keyhole.log
else
    echo -e "$ifConfig" >> /keyhole/keyhole.log
fi
echo >> /keyhole/keyhole.log
echo "Database Diagnostics:" >> /keyhole/keyhole.log
if [ -z "$mysqldProcess" ]; then
    echo "MySql Process: "$mysqldProcess >> /keyhole/keyhole.log
fi
echo "mysqld Limits:" >> /keyhole/keyhole.log
if [[ -s /keyhole/mysqldLimits.txt ]]; then
    cat /keyhole/mysqldLimits.txt | while read line; do echo "$line" >> /keyhole/keyhole.log; done
else
    echo -e "MySQL limits unavailable." >> /keyhole/keyhole.log
fi
echo "Verbose CPU details:" >> /keyhole/keyhole.log
if [[ -s /keyhole/cpuVerbose.txt ]]; then
     cat /keyhole/cpuVerbose.txt | while read line; do echo "$line" >> /keyhole/keyhole.log; done
else
    echo -e "Verbose CPU info unavailable." >> /keyhole/keyhole.log
fi
 
# clean up after myself
rm -f /keyhole/mysqldLimits.txt
rm -f /keyhole/cpuVerbose.txt
rm -f /keyhole/lspci.txt
