/*
  Copyright (c) 2009-2013, Ian Martins (ianxm@jhu.edu)

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
*/

package ihx;

import neko.Lib;

typedef CodeSet = {
    var arrow     :Int;
    var up        :Int;
    var down      :Int;
    var right     :Int;
    var left      :Int;
    var backspace :Int;
    var ctrlc     :Int;
    var enter     :Int;
    var ctrla     :Int;
    var ctrle     :Int;
    var ctrlb     :Int;
    var ctrlf     :Int;
    var ctrld     :Int;
}

/**
   read a command from the console.  handle arrow keys.
**/
class ConsoleReader
{
    public var cmd(default,null) :PartialCommand;
    private var code :Int;
    private var history :History;
    private var codeSet :CodeSet;

    public static function main()
    {
        var cr = new ConsoleReader();
        var cmdStr = cr.readLine();
        Lib.println("\n" + cmdStr);
    }

    public function new()
    {
        code = 0;
        cmd = new PartialCommand();
        history = new History();
        if( Sys.systemName() == "Windows" )
            codeSet = {arrow: 224, up: 72, down: 80, right: 77, left: 75, 
                       backspace: 8, ctrlc: 3, enter: 13,
                       ctrla: 1, ctrle: 5, ctrlb: 2, ctrlf: 6, ctrld: 4 };
        else
            codeSet = {arrow: 27, up: 65, down: 66, right: 67, left: 68,
                       backspace: 127, ctrlc: 3, enter: 13,
                       ctrla: 1, ctrle: 5, ctrlb: 2, ctrlf: 6, ctrld: 4 };
    }

    // get a command from the console
    public function readLine()
    {
        cmd.set("");
        while( true )
        {
            code = Sys.getChar(false);
            // Lib.println("\ngot: " + code +"\n");
            if( code == codeSet.arrow ) // arrow keys
            {
                if( Sys.systemName() != "Windows" )
                    Sys.getChar(false); // burn extra char
                code = Sys.getChar(false);
                
                if ( code == codeSet.up ) { clear(cmd); cmd.set(history.prev()); }
                else if ( code == codeSet.down ) { clear(cmd); cmd.set(history.next()); }
                else if ( code == codeSet.right ) cmd.cursorForward();
                else if ( code == codeSet.left ) cmd.cursorBack();
            }
            else
            {
                if ( code == codeSet.ctrlc ) { Lib.println(""); Sys.exit(1); }
                else if ( code == codeSet.enter ) { Lib.println(""); history.add(cmd.toString()); return cmd.toString(); }
                else if ( code == codeSet.ctrld ) cmd.del(); // del shares code with tilde?
                else if ( code == codeSet.ctrla ) cmd.home();
                else if ( code == codeSet.ctrle ) cmd.end();
                else if ( code == codeSet.ctrlf ) cmd.cursorForward();
                else if ( code == codeSet.ctrlb ) cmd.cursorBack();
                else if ( code == codeSet.backspace ) cmd.backspace();
                else if ( code>=32 && code<=126 ) cmd.addChar(String.fromCharCode(code));
            }
            Lib.print(cmd.toConsole());
        }
        return "";
    }

    public function clear(len)
    {
        Lib.print(cmd.clearString());
    }
}
