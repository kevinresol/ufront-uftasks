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

using Lambda;
import neko.Lib;
import haxe.io.Eof;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;
import ihx.program.Program;

class NekoEval
{
    public var classpath(default,null) :Array<String>;
    public var libs(default,null) :Array<String>;
    public var tmpSuffix(default,null) :String;
    private var errRegex :EReg;
    private var tmpDir :String;
    private var tmpHxFname :String;
    private var tmpHxPath :String;
    private var tmpNekoPath :String;

    public function new()
    {
        classpath = new Array<String>();
        libs = new Array<String>();
        errRegex = ~/.*IhxProgram_[0-9]*.hx:.* characters [0-9\-]+ : (.*)/;
        tmpDir = (Sys.systemName()=="Windows") ? Sys.getEnv("TEMP") : "/tmp";
        tmpSuffix = StringTools.lpad(Std.string(Std.random(9999)), "0", 4);
        tmpHxFname = "IhxProgram_"+ tmpSuffix +".hx";
        tmpHxPath = tmpDir +"/" + tmpHxFname;
        tmpNekoPath = tmpDir +"/ihx_out_"+ tmpSuffix +".n";
    }

    public function evaluate(progStr)
    {
        var ret = "";
        File.saveContent(tmpHxPath, progStr);
        var args = ["-neko", tmpNekoPath, "-cp", tmpDir, "-main", tmpHxFname, "-cmd", "neko "+tmpNekoPath];
        classpath.iter( function(ii){ args.push("-cp"); args.push(ii); });
        libs.iter( function(ii){ args.push("-lib"); args.push(ii); });
        var proc = new Process("haxe", args);
        var sb = new StringBuf();
        try {
            var pastOld = false;
            while( true )
            {
                var line = proc.stdout.readLine();
                if( !pastOld && line==Program.separator )
                {
                    pastOld = true;
                    continue;
                }
                if( pastOld )
                    sb.add(line+"\n");
                ret = sb.toString().substr(0, sb.toString().length-1);
            }
        }
        catch ( eof :Eof ) { }
        try {
            while( true )
            {
                var line = proc.stderr.readLine();
                if( errRegex.match(line) )
                    sb.add("error: "+ errRegex.matched(1) +"\n");
                else
                    sb.add("error: "+ line +"\n");
                ret = sb.toString();
            }
        }
        catch ( eof :Eof ) { }

        if( FileSystem.exists(tmpHxPath) )
            FileSystem.deleteFile(tmpHxPath);
        if( FileSystem.exists(tmpNekoPath) )
            FileSystem.deleteFile(tmpNekoPath);

        if( proc.exitCode()!=0 )
            throw ret;
        return ret;
   }
}
