MODULE_NAME='mConfigFromFile'       (
                                        dev vdvObject
                                    )

(***********************************************************)
#DEFINE USING_NAV_MODULE_BASE_CALLBACKS
#DEFINE USING_NAV_MODULE_BASE_PROPERTY_EVENT_CALLBACK
#include 'NAVFoundation.Core.axi'
#include 'NAVFoundation.ModuleBase.axi'
#include 'NAVFoundation.StringUtils.axi'
#include 'NAVFoundation.FileUtils.axi'

/*
 _   _                       _          ___     __
| \ | | ___  _ __ __ _  __ _| |_ ___   / \ \   / /
|  \| |/ _ \| '__/ _` |/ _` | __/ _ \ / _ \ \ / /
| |\  | (_) | | | (_| | (_| | ||  __// ___ \ V /
|_| \_|\___/|_|  \__, |\__,_|\__\___/_/   \_\_/
                 |___/

MIT License

Copyright (c) 2023 Norgate AV Services Limited

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

constant integer MAX_LINES = 500
constant integer MAX_LINE_LENGTH = 255

constant char EOF[] = '[END_OF_FILE]'

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile char path[255] = '/config.txt'


(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)

define_function GetConfig(char path[]) {
    stack_var char data[MAX_LINES * MAX_LINE_LENGTH]
    stack_var char lines[MAX_LINES][MAX_LINE_LENGTH]
    stack_var integer count
    stack_var slong result
    stack_var long total
    stack_var integer x

    if (!length_array(path)) {
        return
    }

    result = NAVFileRead(path, data)

    if (result <= 0) {
        return
    }

    total = type_cast(result)

    NAVLog("'mConfigFromFile => Total Bytes Read: ', itoa(total)")

    count = NAVSplitString(data, "NAV_LF", lines)

    if (count <= 0) {
        return
    }

    for (x = 1; x <= count; x++) {
        if (NAVContains(lines[x], EOF)) {
            break
        }

        {
            stack_var char line[MAX_LINE_LENGTH]
            stack_var char value[255]

            line = NAVTrimString(lines[x])
            value = NAVGetStringBetween(line, '////', '////')

            if (!length_array(value) && !NAVContains(line, '////////')) {
                continue
            }

            NAVLog("'mConfigFromFile => Line ', itoa(x), ': ', line")

            if (!length_array(value)) {
                continue
            }

            NAVLog("'mConfigFromFile => Line ', itoa(x), ' Value: ', value")

            send_string vdvObject, "'LINE-', itoa(x), ',', value"
        }
    }

    send_string vdvObject, "'DONE'"
}


#IF_DEFINED USING_NAV_MODULE_BASE_PROPERTY_EVENT_CALLBACK
define_function NAVModulePropertyEventCallback(_NAVModulePropertyEvent event) {
    if (event.Device != vdvObject) {
        return
    }

    switch (event.Name) {
        case 'PATH': {
            path = NAVTrimString(event.Args[1])
        }
    }
}
#END_IF


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START {

}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

data_event[vdvObject] {
    command: {
        stack_var _NAVSnapiMessage message

        NAVParseSnapiMessage(data.text, message)

        switch (message.Header) {
            case 'GET_TEXT':
            case 'GET_CONFIG': {
                if (length_array(message.Parameter[1])) {
                    path = NAVTrimString(message.Parameter[1])
                }

                GetConfig(path)
            }
        }
    }
}


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
