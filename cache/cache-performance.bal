// This code is extracted from
// https://github.com/chethiya/ballerina-cache/blob/master/src/cache/tests/lru-cache-performance_test.bal
// and updated for Ballerina cache v2.0.0 implementation.

import ballerina/io;
import ballerina/math;
import ballerina/time;
import ballerina/cache;

int putQ = 1000000;
int getQ = 1000000;

function simulateGetForPerformance(cache:Cache cache) {
    int hitRate = 0;
    int i = 0;
    int rangeEndValue = cache.capacity() / 10;
    if (rangeEndValue == 0) {
        rangeEndValue = 1;
    }
    int started = -1;
    int startTime = time:nanoTime();
    while (i < getQ) {
        boolean small = <int>math:randomInRange(0, 1) == 0 ? true : false;
        int getIndex = <int>math:randomInRange(0, small ? rangeEndValue : getQ);
        string getKey = getIndex.toString();
        any | error getValue = cache.get(getKey);
        if (getValue is int) {
            hitRate += 1;
            if (started == -1) {
                started = i;
            }
        }
        i += 1;
    }
    int curTime = time:nanoTime();
    io:println("Worker time: ", curTime - startTime, " (ns);", " Hit rate: ", hitRate, "; Started at: ", started);
}

public function evaluatePerformance(int capacity) {
    io:println("Testing performance with the cache capacity: ", capacity);
    cache:CacheConfig config = {
        capacity: capacity,
        evictionFactor: 0.25
    };
    cache:Cache cache = new(config);

    int startTime = time:nanoTime();
    int i = 0;
    int hitRate = 0;
    int rangeEndValue = capacity / 10;
    if (rangeEndValue == 0) {
        rangeEndValue = 1;
    }

    fork {
        worker w1 {
            simulateGetForPerformance(cache);
        }
        worker w2 {
            simulateGetForPerformance(cache);
        }
        worker w3 {
            simulateGetForPerformance(cache);
        }
        worker w4 {
            simulateGetForPerformance(cache);
        }
    }

    while (i < putQ) {
        string key = i.toString();
        error? r = cache.put(key, i);
        int getIndex = i % rangeEndValue;
        string getKey = getIndex.toString();
        any | error getValue = cache.get(getKey);
        if (getValue is int) {
            hitRate += 1;
        }
        i += 1;
    }
    int curTime = time:nanoTime();
    io:println("Cache put time is ", curTime - startTime, " (ns)", " and hit rate is ", hitRate);
    _ = wait {w1, w2, w3, w4};
    int endTime = time:nanoTime();
    io:println("Total time: ", (endTime - startTime) / (1000 * 1000 * 1000), " (s)");
}
