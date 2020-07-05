#
#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details about the copyright / license.
# 
#          Testing for Simple In-Memory Cache - Table/Dictionary
#

import mccache/simpleCache, json, unittest, os

# record type(s)
type UserColl = object
    id: string  # uuid
    username:string
    firstname: string
    lastname: string
    middlename: string
    email: string
    recovery_email: string
    lang: string
    is_active: bool
    desc: string
    profile: string  # jsonb

# variables for test-values
var
    cacheValue: JsonNode = parseJson("""{"firstName": "Abi", "lastName": "Akindele", "location": "Toronto-Canada"}""")
    cacheKey: string = """{"name": "Tab1", "location": "Toronto"}"""
    expiryTime: Positive = 5 # in seconds

test "should set and return valid cacheValue":
    let setCache = setCache(cacheKey, cacheValue, expiryTime )
    if setCache.ok:
        # get cache content
        let res = getCache(cacheKey)
        echo "get-cache-response: ", res
        check res.ok == true
        check res.value == cacheValue
        check res.message == "task completed successfully"
    else:
        check setCache.ok == false

test "should clear the cache and return nil/empty value":
    let cache = clearCache()
    if cache.ok:
        # get cache content
        let res = getCache(cacheKey)
        echo "get-cache-response: ", res
        check cache.message == "task completed successfully"
        check res.ok == false
        check res.value == nil
        check res.message == "cache info does not exist"
    else:
        check cache.ok == false

test "should set and return valid cacheValue -> before timeout/expiration)":
    # change the expiry time to 2 seconds
    expiryTime = 2
    let setCache = setCache(cacheKey, cacheValue, expiryTime )
    if setCache.ok:
        # get cache content
        let res = getCache(cacheKey)
        echo "get-cache-response: ", res
        check res.ok == true
        check res.value == cacheValue
        check res.message == "task completed successfully"

test "should return nil value after timeout/expiration":
    # sleep for 3 seconds to ensure cache expired
    sleep(3000)
    # get cache content
    let res = getCache(cacheKey)
    echo "get-cache-response: ", res
    check res.ok == false
    check res.value == nil
    check res.message == "cache expired and deleted"

test "should set and return valid cacheValue (repeat prior to deleteCache testing)":
    expiryTime = 10
    let setCache = setCache(cacheKey, cacheValue, expiryTime )
    if setCache.ok:
        # get cache content
        let res = getCache(cacheKey)
        echo "get-cache-response: ", res
        check res.ok == true
        check res.value == cacheValue
        check res.message == "task completed successfully"
    else:
        check setCache.ok == false

test "should delete the cache and return nil/empty value":
    let cache = deleteCache(cacheKey)
    if cache.ok:
        # get cache content
        let res = getCache(cacheKey)
        echo "get-cache-response: ", res
        check cache.message == "task completed successfully"
        check res.ok == false
        check res.value == nil
        check res.message == "cache info does not exist"
    else:
        check cache.ok == false
