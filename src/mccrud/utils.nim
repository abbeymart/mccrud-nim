# Utility functions / procs

import times, strutils, tables
import mcresponse
import types

## strToBool procedure converts a string parameter to a boolean
proc strToBool*(val: string): bool =
    try:
        let strVal = val.toLower
        if strVal == "true" or strVal == "t" or strVal == "yes" or strVal == "y":
            return true
        elif val.parseInt > 0:
            return true
        else:
            return false 
    except:
        return false

## strToSeq procedure converts a csv or stringified array to seq[string]
proc strToSeq*(val: string): seq[string] =
    try:
        var seqRes: seq[string] = @[]
        var strVal: seq[string]
        if val.contains('[') and val.contains(']'):
            strVal = val.split({'[', ',', ']'})
        elif val.contains('[') and not val.contains(']'):
            strVal = val.split({',', '['})
        elif val.contains(']') and not val.contains('['):
            strVal = val.split({',', ']'})        
        else:
            strVal = val.split(',')
    
        for item in strVal:
            seqRes.add(item.strip)
        return seqRes
    except:
        return @[]    

## strToTime converts time from string to Time format
proc strToTime*(val: string): Time =
    try:
        result = fromUnix(val.parseInt)
    except:
        # return the current time
        return getTime()

## toCamelCase compose the cameCase fieldname, with words separators.
## It accepts words/text and separator(' ', '_', '__', '.') as args=>parameters.
## Default seperation => "_"
proc toCamelCase(text: string, sep = "_"): string =
    result = ""
    let textArray = text.split(sep)
    # convert the first word to lowercase
    let firstWord = textArray[0].toLower()
    # convert other words: first letter to upper case and other letters to lowercase
    # ^1 => < textArray.len or textArray.len-1
    let remWords = textArray[1 .. ^1]
    var
        otherWords: seq[string]
    
    for item in remWords:
    # convert first letter to upper case
        let itemStr = item.split("")
        let item0 = (itemStr[0]).toLower()
        # convert other letters to lowercase
        let item1N = (itemStr[1 .. ^1]).join("").toLower()
        let itemString = item0 & item1N
        otherWords.add(itemString)

    result = firstWord & otherWords.join("")

## getParamsResMessage compute the response-message from the message-object
func getParamsMessage(msgObject: MessageObjectType): ResponseMessage =
    var messages = ""

    for k, v in msgObject.pairs:
        if messages != "":
            messages = messages & " | " & k & ": " & v
        else:
            messages = k & ": " & v
    
    result = getResMessage("paramsError", ResponseMessage(
        code = "paramsError",
        message = messages,
        value = nil
    ))

proc ExcludeEmptyIdFromTableRecord(rec: Table[string, auto]): Table[string, auto] =
    result = Table[string, auto]

    
