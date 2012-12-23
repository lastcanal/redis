start_server {tags {"archive"}} {

    test "archive - can archived keys be recovered?" {
        # make sure to start with a blank instance
        r flushall 
        # Turn on our key archival system
        r config set keyarchive yes
        # Get the current memory limit and calculate a new limit.
        # We just add 100k to the current memory size so that it is
        # fast for us to reach that limit.
        set used [s used_memory]
        set limit [expr {$used+100*1024}]
        r config set maxmemory $limit
        r config set maxmemory-policy allkeys-random
        # Now add keys until the limit is almost reached.
        set numkeys 0
        while 1 {
            # Odd keys are volatile
            # Even keys are non volatile
            if {$numkeys % 2} {
                r setex "key:$numkeys" 10000 x
            } else {
                r set "key:$numkeys" x
            }
            if {[s used_memory]+4096 > $limit} {
                assert {$numkeys > 10}
                break
            }
            incr numkeys
        }
        # If we add the same number of keys already added again, we
        # should still be under the limit.
        for {set j 0} {$j < $numkeys} {incr j} {
            r setex [randomKey] 10000 x
        }
        assert {[s used_memory] < ($limit+4096)}
        # However all our non volatile keys should be here.
        for {set j 0} {$j < $numkeys} {incr j 2} {
            assert {[r exists "key:$j"]}
        }
    }

}
