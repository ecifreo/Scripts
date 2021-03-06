# This is heavily influenced by the corosync.conf man page (based on the original
# openais.conf man page). It endevours to make some of the explanations more
# accessible to beginners and to create a working configuration file with all
# options inline and explained. Please note that errors in this file are mine; 
# *NOT* of the Corosync or OpenAIS communities in general.
 
# To Do:
# - Better explain the 'logging { logger { } }' subdirective.
# - Explain the 'event { }' directive.
#
# Core ideas needing further explanation:
# - Totem protocol
# - Forming a new configuration
# - token
# - representative (see the 'hold' variable)
# - membership protocol
# - The math behind 'token_retransmit', 'hold' and 'send_join'.
# - What is the 'merge' default?
# - Is there a functional difference between "processor" and "node"? Ie: is a
#   "processor" a specific core in a CPU?
 
# In Corosync, this option can be set to define a compatibility level to run at.
# Currently, the only two values are 'whitetank' and 'none'. The default is
# 'whitetank', which tells corosync to run compatible with OpenAIS 0.80.x. This
# will slow things down a bit, but will allow you to run corosync using old
# openais.conf files.
compatibility: whitetank
 
# Totem Protocol options.
# Be sure to understand and test the effects of changing values in this 'totem'
# directive. Generally speaking, the defaults (outside of the 'interface'
# directive) are sane and usable.
totem {
	# This is the version number of this configuration file's format.
	# Unlike 'cluster.conf's 'config_version', this value *does not*
	# change. Further, it must always be set to '2'.
	version: 2
 
	# When set to 'on', data will be encrypted using sober128 and that
	# HMAC/SHA1 is used for authentication. This adds a 36 byes header to
	# all totem messages. When enabled, this accounts for 75% of the CPU
	# usage used by the aisexec. Further, it will substantially increase
	# the CPU requirements of your nodes and will reduce transfer speeds
	# a non-trivial amount. For this reason, only enable this when you
	# are using an unsecure network and be sure to test to see how much
	# overhead it encures so that you can increase hardware resources if
	# needed. Please see 'man corosync.conf' for two specific examples of
	# performance trade-offs seen when enabling this. The default is 'on'.
	secauth: off
 
	# When 'secauth' is 'off', this variable is ignored. When 'secauth' is
	# 'on', this defined how many threads may be used for encypting and
	# sending multicast messages. A value of '0' disabled multiple threads.
	# This is most useful on non-SMP machines. (MADI: why?)
	threads: 0
 
	# This is a 32-bit value identifying this node when joining the CLM.
	# When using IPv4 addresses, this is an optional argument. When not
	# specified, the 'bindnetaddr' IP address specified in the 'interface'
	# directive with the 'ringnumber' '0' is used to generate this value.
	# However, if the IP address is IPv6, this mechanism can not be used
	# and you must manually specify a 'nodeid'. A 'nodeid' of '0' is
	# reserved and must not be used.
	#nodeid: 10
 
	# This defined the size of the maximum transfer unit in bytes. The
	# default is 1500. If you want to use jumbo frames, frames larger than
	# 1500, *all* devices in your network *must* also support jumbo frames
	# and all hosts must also have their MTU set to the same size defined
	# below.
	# NOTE 1: Some hardware that claims to support jumbo frames (aka: large
	# frames) are actually limited to a max of 4500 or 9000 bytes. If you
	# find the network frequently reconfigures when using multicast, you
	# probably have hardware that isn't supporting your frame size.
	# NOTE 2; Linux adds 18 bytes to the packets generated by totem, so if
	# you are having trouble, drop the size of your frames to n-18. For
	# example, if you want to use 9000, set this to 8982.
	# NOTE 3: The man page describes a scenario where increasing the frame
	# size to 9000 (8982) increased throughput from 30MB/s to 60MB/s.
	net_mtu: 1500
 
	# This defines what Virtual Synchrony Filter type is used to identify a
	# primary component. The prefered and default option is 'ykd' dynamic
	# linear voting. This consumes a lot of memory on clusters larger than
	# 32 nodes though. If you want to use more than 32 nodes, please see
	# the man page for details. If you set this to 'none', then AMF 
	# (Availability Management Framework) and DLCK (Distributed LoCKing)
	# are not safe to use. Leave this as 'ykd' unless you are sure you need
	# to change it.
	# Valid options; ykd, none
	vfstype: ykd
 
	# This is the number of milliseconds that totem will wait before
	# declaring a token to be lost. Once a token loss is declared, the
	# configuration will be reformed, which usually takes an additional
	# 50 milliseconds. The default is 1000 (1 second).
	# MADI: Define 'reforming a new configuration'.
	token: 1000
 
	# This is the number of times that a token will be retransmitted before
	# a new configuration is formed. When set, 'token_retransmit' and
	# 'hold' will automatically be calculated using this and the 'token'
	# value. The default is '4'.
	retransmits_before_loss: 4
 
	# This is the number of milliseconds between re-send attempts when a
	# token isn't received as expected. In general, do not set this as
	# corosync will automatically calculate this based on the 'token' value
	# divided by the 'retransmits_before_loss'. In generaly, this should
	# be less than the resulting number. For example, with a token of
	# '1000' divided by the 'retransmits_before_loss' value of '4', the
	# result is '250', but because this needs to be somewhat less, '238'
	# is used instead.
	#token_retransmit: 238
 
	# This is the number of milliseconds that a token should be held by the
	# representative when the protocol is under low utilization. This is
	# automatically calculated using the 'token' and
	# 'retransmits_before_loss' variables and should not be set ot altered
	# without fully understanding how this will effect corosync.
	#hold: 180
 
	# This tells corosync how long to wait, in milliseconds, for join
	# messages in the membership protocol.
	join: 100
 
	# This variable is a type of flood control that tells a node how long
	# to wait before sending a join message. Specifically, a node will wait
	# between '0' and this value before sending to help prevent flooding
	# the network with join messages on large rings. With clusters under 32
	# nodes, leave this set to it's default of '0'. With 128 nodes, a value
	# of '80' milliseconds is sane.
	send_join: 0
 
	# This is the timeout in milliseconds that corosync will wait for
	# consensus to be achieved before starting a new round of membership
	# configuration. The default is '200'.
	consensus: 200
 
	# This is the amount of time, in milliseconds, that corosync will wait
	# before checking if an interface is back up after it has gone down.
	# The default is '1000'.
	downcheck: 1000
 
	# This constant is the number of times that the token can be passed
	# without any expected messages before a new configuration is formed.
	# The default is '50'.
	fail_to_recv_const: 50
 
	# When multicast traffic stops, this tells corosync how long, in
	# milliseconds, to wait before checking for a partition. The default is
	# '200'.
	merge: 200
 
	# This constant defines how many times the token can be passed without
	# and multicast traffic before the 'merge' detection timeout starts.
	# The default is '30'.
	seqno_unchanged_const: 30
 
	# This constant sets the number of messages that a given node may send
	# on one pass of the token. If all nodes perform equally well, this can
	# be set to a high number, like 300. However, if your cluster has a
	# large number of nodes, this could induce latency. If you have 16 or
	# more nodes, you should set this to the default of '50'. If, however,
	# one or more nodes are slower than the rest, this should be set to no
	# more than 256000/netmtu (ie: 256000/9000 = 28.4, so '25' is good).
	# This will avoid overflowing the kernel's transmit buffers. Should
	# this happen, there will be retransmit notices in the notification log
	# file and performance will suffer.
	window_size: 300
 
	# MADI: How is this different from 'window_size'?
	# This constant sets the maximum number of messages that may be sent by
	# node on receipt of the of the token. This is limited to 256000/netmtu
	# (ie: 256000/9000 = 28.4, so '25' is good). This is to prevent
	# overflowing the kernel's transmit buffers. The default is 17.
	max_messages: 25
 
	### Redundant Ring Protocol options are below. These are ignored if
	### only one 'interface' directive is defined.
 
	# This is used to control how the Redundant Ring Protocol is used. If
	# you only have one 'interface' directive, the default is 'none'. If
	# you have two, then please set 'active' or 'passive'. The trade off
	# is that, when the network is degraded, 'active' provides lower
	# latency from transmit to delivery and 'passive' may nearly double the
	# speed of the totem protocol when not CPU bound.
	# Valid options: none, active, passive.
	rrp_mode: passive
 
	# The next three variables are relevant depending on which mode 
	# 'rrp_mode' is set to. Both modes use 'rrp_problem_count_threshold'
	# but only 'active' uses 'rrp_problem_count_timeout' and 
	# 'rrp_token_expired_timeout'.
	# 
	# - In 'active' mode:
	# If a token doesn't arrive in 'rrp_token_expired_timeout' milliseconds
	# an internal counter called 'problem_count' is incremented by 1. If a
	# token arrives within 'rrp_problem_count_timeout' however, the
	# internal decreases by '1'. If the internal counter equals or exceeds
	# the 'rrp_problem_count_threshold' at any time, the effected interface
	# will be flagged as faulty and it will no longer be used.
	# 
	# - In 'passive' mode:
	# The two interfaces have internal counters called 'token_recv_count'
	# and 'mcast_recv_count' that are incremented by 1 each time a token
	# or multicast message is received, respectively. These counts for each
	# interface is counted and if the counts should differ by more than
	# 'rrp_problem_count_threshold', then the interface with the lower
	# count is flagged as faulty and it will no longer be used.
	# 
	# If an interface is flagged as faulty, an administrator will need to
	# manually re-enable it.
 
	# The default problem count timeout is '1000' milliseconds.
	rrp_problem_count_timeout: 1000
 
	# The default problem count threshold is '20'.
	rrp_problem_count_threshold: 20
 
	# This is the time in milliseconds to wait before incrementing the
	# internal problem counter. Normally, this variable is automatically
	# calculated by corosync and, thus, should not be defined here without
	# fully understanding the effects of doing so.
	# 
	# In short; The should always be at least 'rrp_problem_count_timeout'
	# minus 50 milliseconds with the result being divided by 
	# 'rrp_problem_count_threshold' or else a reconfiguration can occur.
	# Using the default values then, the default is (1000 - 50)/20=47.5,
	# rounded down to '47'.
	#rrp_token_expired_timeout: 47
 
	### Below here are the optional Heartbeat Mechanism options.
 
	# Setting this to a non-0 value switches from token passing to network
	# heartbeat as the failure detection mechanism. This reduces the time
	# needed to detect a failure, but increases the chance that a fault
	# will be declared when none exists. The reason for this is that 
	# heartbeat uses the network and, if the network is lossy, heartbeat
	# packets could be lost. To that end, this setting tells corosync how
	# many heartbeat failures are allowed before a fault is declared. This
	# should only be used on networks where improved fault response time is
	# needed *and* the network is fast and reliable. The default is '0',
	# thus disabling this feature.
	#heartbeat_failures_allowed: 0
 
	# This is the approximate delay on between transmitting and receiving
	# of heartbeat packets on your network. This should be determined by
	# the network engineer. Do not adjust this setting without fully
	# understanding the impact of your change. The default is '50'.
	max_network_delay: 50
 
	### Below here are the 'interface' directive(s).
 
	# At least one 'interface' directive is required within the 'totem'
	# directive. When two are specified, the one with 'ringnumber' of '0'
	# is the primary ring and the second with 'ringnumber' of '1' is the
	# backup ring.
	interface {
		# Increment the ring number for each 'interface' directive.
		ringnumber:  0
 
		# This must match the subnet of this interface. The final octal
		# must be '0'. In this case, this directive will bind to the
		# interface on the 192.168.1.0/24 subnet, so this should be set
		# to '192.168.1.0'. This can be an IPv6 address, however, you
		# will be required to set the 'nodeid' in the 'totem' directive
		# above. Further, there will be no automatic interface
		# selection within a specified subnet as there is with IPv4.
		# In this case, the primary ring will be on the interface with
		# IPs on the 10.0.0.0/24 network (ie: eth1).
		bindnetaddr: 10.0.0.0
 
		# This is the multicast address used by Corosync. Avoid the
		# '224.0.0.0/8' range as that is used for configuration. If you
		# use an IPv6 address, be sure to specify a 'nodeid' in the 
		# 'totem' directive above.
		mcastaddr:   226.94.1.1
 
		# This is the UDP port used with the multicast address above.
		mcastport:   5405
	}
 
	# This is a second optional, redundant interface directive. If you use
	# two 'interface' directives, be sure to review the four 'rrp_*'
	# variables.
	# Note that two is the maximum number of interface directives.
	interface {
		# Increment the ring number for each 'interface' directive.
		ringnumber:  1
		# In this case, the backup ring will be on the interface with
		# IPs on storage network's 10.0.1.0/24 network (ie: eth1).
		bindnetaddr: 10.0.1.0
		# MADI: Does this have to be different? How much different?
		#       Can I just use a different port?
		mcastaddr:   227.94.1.2
		# MADI: If this is different, can 'mcastaddr' be the same?
		mcastport:   5405
	}
}
 
# This directive controls how Corosync logs it's messages. All variables here
# are optional.
logging {
	# Setting this to 'on' will replace the logger name in the log entries
	# with the file and line generating the log entry. The default is
	# 'off'.
	fileline: off
 
	# This controls whether a timestamp is recorded in the log files.
	# Valid options are 'off' and 'on', with 'off' being the default.
	timestamp: on
 
	# This control whether the function name generating the log entry is
	# recorded or not. Valid options are 'off' and 'on', with 'off' being
	# the default.
	function_name: off
 
	# These three options control where log messages are sent. Logs can be
	# sent to two or all three. The three options are: 'to_logfile',
	# 'to_syslog' and 'to_stderr'. All three can either be 'yes' or 'no'.
	# When set to 'yes', logs are sent to the relative destination. The
	# default is to write to the syslog and to stderr.
 
	# This directs output to a file. If set to 'yes', you must set a
	# 'logfile' argument below. Default is 'no'.
	to_logfile: yes
 
	# Default is 'yes'.
	to_syslog: yes
 
	# Default is 'yes'.
	to_stderr: no
 
	# When 'to_logfile: yes' is set, this is required. It is the full path
	# and file name to write the logs to.
	logfile: /var/log/corosync.log
 
	# Setting this to 'on', the default, generates a lot of debug messages
	# in the log. It is generally not advised unless you are tracing a
	# specific bug.
	debug: off
 
	# When writing to syslog, this sets the syslog facility to use. Valid
	# options are:
	# daemon, local0, local1, local2, local3, local4, local5, local6 and
	# local7
	# The default is 'daemon'.
	syslog_facility: daemon
 
	# This is an optional directive that controls detailed logging
	# features. Generally, this is only needed by developers.
	#logger_subsys {
		# This specifies the identity logging being specified.
		# MADI: What?
		#ident: ?
 
		# This enables or disables debug log messages for the component
		# identified above. The default is 'off'.
		#debug: off
 
		# This specifies which tags should be logged for this
		# component. This is only valid when debug is enabled above.
		# Multiple tags are specified with a pipe (|) as the logical
		# OR seperator. The default is 'none'.
		#tags: enter|return|trace1|trace2
	#}
}
 
# This must exist and be set to disabled if you have openais installed. It's
# safe to include it regardless. AMF is not currently supported.
amf {
        mode: disabled
}