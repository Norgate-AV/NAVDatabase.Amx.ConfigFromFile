MODULE_NAME='mConfigFromFile'       (
                                        dev vdvObject
                                    )

(***********************************************************)
#include 'NAVFoundation.ModuleBase.axi'
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

constant char EOF[] = '[END_OF_FILE]'

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

volatile char filePath[NAV_MAX_BUFFER] = '\'
volatile char fileName[NAV_MAX_BUFFER] = 'config.txt'


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

define_function Get(char path[], char name[]) {
    stack_var long handle
    stack_var char buffer[NAV_MAX_BUFFER]
    stack_var integer line
    stack_var slong result
    stack_var char data[NAV_MAX_BUFFER]

    if (!length_array(path) || !length_array(name)) {
        return
    }

    result = NAVFileOpen("path, name", 'r')

    if (result <= 0) {
        return
    }

    handle = type_cast(result)

    result = 1

    while (result > 0) {
        result = NAVFileReadLine(handle, buffer)

        if (result <= 0) {
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mConfigFromFile => 0 Bytes Read'")
            continue
        }

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mConfigFromFile => Line: ', buffer")

        if (NAVContains(buffer, EOF)) {
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mConfigFromFile => Found EOF'")
            break
        }

        data = NAVGetStringBetween(buffer, '////', '////')

        if (!length_array(data) && !NAVContains(buffer, '////////')) {
            NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mConfigFromFile => Empty Line'")
            continue
        }

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG, "'mConfigFromFile => Line Value: ', data")

        line++
        send_string vdvObject, "'LINE-', itoa(line), ',', data"
    }

    NAVFileClose(handle)

    send_string vdvObject, "'DONE'"
}


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

        NAVErrorLog(NAV_LOG_LEVEL_DEBUG,
                    NAVFormatStandardLogMessage(NAV_STANDARD_LOG_MESSAGE_TYPE_COMMAND_FROM,
                                                data.device,
                                                data.text))

        NAVParseSnapiMessage(data.text, message)

        switch (message.Header) {
            case 'PROPERTY': {
                switch (message.Parameter[1]) {
                    case 'FILE_NAME': {
                        fileName = message.Parameter[2]
                    }
                    case 'FILE_PATH': {
                        filePath = message.Parameter[2]
                    }
                }
            }
            case 'GET_TEXT': {
                Get(filePath, fileName)
            }
        }
    }
}


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
