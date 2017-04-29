#!/usr/bin/perl
###########################################################################
# Installer 4J 0.3
# Install/remove Java tools and their dependencies
#
# Copyright (C) 2015-2017 Andrey Ponomarenko's ABI Laboratory
#
# Written by Andrey Ponomarenko
#
# REQUIREMENTS
# ============
#  Perl 5 (5.8 or newer)
#  cURL
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License or the GNU Lesser
# General Public License as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# and the GNU Lesser General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.
########################################################################### 
use strict;
use Getopt::Long;
Getopt::Long::Configure ("posix_default", "no_ignore_case");
use File::Path qw(mkpath rmtree);
use File::Temp qw(tempdir);
use File::Basename qw(basename);
use Cwd qw(cwd);

my $TOOL_VERSION = "0.3";
my $ORIG_DIR = cwd();
my $TMP_DIR = tempdir(CLEANUP=>1);

my %DEPS = (
    "japi-tracker"            => ["japi-monitor", "japi-compliance-checker", "pkgdiff", "rfcdiff"],
    "japi-monitor"            => ["curl"],
    "japi-compliance-checker" => ["javap"],
    "pkgdiff"                 => ["rfcdiff", "diff"],
    "rfcdiff"                 => ["diff", "wdiff", "awk"]
);

my %VER = (
    "japi-tracker"            => "1.1",
    "japi-monitor"            => "1.1",
    "japi-compliance-checker" => "2.1",
    "pkgdiff"                 => "1.7.2"
);

my %ORDER = (
    "japi-tracker"            => 1,
    "japi-monitor"            => 2,
    "japi-compliance-checker" => 3,
    "pkgdiff"                 => 4,
    "curl"                    => 5
);

my ($Prefix, $Help, $Install, $Remove);
my $CmdName = basename($0);

my $HELP_MSG = "
NAME:
  Installer for Java tools from the github.com/lvc project

USAGE: $CmdName [options] [target]

EXAMPLE:
  sudo perl $CmdName -install -prefix /usr japi-tracker
  sudo perl $CmdName -remove -prefix /usr japi-tracker

OPTIONS:
  -h|-help
      Print this help.

  -prefix PREFIX
      Install files in PREFIX [/usr/local].

  -install
      Command to install the tool.

  -remove
      Command to remove the tool.
\n";

if(not @ARGV)
{
    print $HELP_MSG;
    exit(0);
}

GetOptions(
    "h|help!" => \$Help,
    "prefix=s" => \$Prefix,
    "install!" => \$Install,
    "remove!" => \$Remove
) or exit(1);

sub getDeps($)
{
    my $Tool = $_[0];
    
    my $Deps = $DEPS{$Tool};
    
    my %CompleteDeps = ();
    
    foreach my $Dep (@{$Deps})
    {
        $CompleteDeps{$Dep} = 1;
        
        if(defined $DEPS{$Dep})
        {
            foreach my $SubDep (getDeps($Dep))
            {
                $CompleteDeps{$SubDep} = 1;
            }
        }
    }
    
    my (@First, @Last) = ();
    
    foreach my $Dep (sort keys(%CompleteDeps))
    {
        if(defined $ORDER{$Dep}) {
            push(@First, $Dep);
        }
        else {
            push(@Last, $Dep);
        }
    }
    
    my @Res = sort {$ORDER{$a}<=>$ORDER{$b}} @First;
    push(@Res, @Last);
    
    return @Res 
}

sub check_Cmd($)
{
    my $Cmd = $_[0];
    return "" if(not $Cmd);
    
    foreach my $Path (sort {length($a)<=>length($b)} split(/:/, $ENV{"PATH"}))
    {
        if(-x $Path."/".$Cmd) {
            return 1;
        }
    }
    return 0;
}

sub scenario()
{
    if($Help)
    {
        print $HELP_MSG;
        exit(0);
    }
    
    if(not $Install and not $Remove)
    {
        print STDERR "ERROR: command is not selected (-install or -remove)\n";
        exit(1);
    }
    
    if(not @ARGV)
    {
        print STDERR "ERROR: please specify tool to install/remove\n";
        exit(1);
    }
    
    my $Target = $ARGV[0];
    
    if(not defined $DEPS{$Target})
    {
        print STDERR "ERROR: unknown tool\n";
        exit(1);
    }
    
    if($Prefix ne "/") {
        $Prefix=~s/[\/]+\Z//g;
    }
    
    if(not $Prefix)
    { # default prefix
        $Prefix = "/usr";
    }
    
    if($Prefix!~/\A\//)
    {
        print STDERR "ERROR: prefix is not absolute path\n";
        exit(1);
    }
    
    if(not -d $Prefix)
    {
        print STDERR "ERROR: you should create prefix directory first\n";
        exit(1);
    }
    
    if(not -w $Prefix)
    {
        print STDERR "ERROR: you should be root\n";
        exit(1);
    }
    
    if(not check_Cmd("curl"))
    {
        print STDERR "ERROR: curl is not installed\n";
        exit(1);
    }
    
    my @Deps = ($Target, getDeps($Target));
    my %NotInstalled = ();
    
    foreach my $Dep (@Deps)
    {
        if(my $V = $VER{$Dep})
        {
            my $Action = "install";
            
            if($Remove and not $Install)
            {
                $Action = "uninstall";
                
                if(not -x $Prefix."/bin/".$Dep)
                {
                    if($Target eq $Dep) {
                        print "$Dep is not installed\n";
                    }
                    next;
                }
            }
            
            print ucfirst($Action)."ing $Dep $V\n";
            
            my $Url = "https://github.com/lvc/$Dep/archive/$V.tar.gz";
            my $BuildDir = $TMP_DIR."/build";
            
            mkpath($BuildDir);
            chdir($BuildDir);
            
            qx/curl -L $Url --output archive.tar.gz >\/dev\/null 2>&1/;
            if($? or not -B "archive.tar.gz")
            {
                print STDERR "ERROR: failed to download $Dep $V\n";
                chdir($ORIG_DIR);
                exit(1);
            }
            
            qx/tar -xf archive.tar.gz/;
            if($?)
            {
                print STDERR "ERROR: failed to extract $Dep $V\n";
                chdir($ORIG_DIR);
                exit(1);
            }
            chdir($Dep."-".$VER{$Dep});
            
            qx/make $Action prefix="$Prefix" >\/dev\/null 2>&1/;
            if($?)
            {
                print STDERR "ERROR: failed to $Action $Dep $V\n";
                chdir($ORIG_DIR);
                exit(1);
            }
            
            chdir($ORIG_DIR);
            
            rmtree($BuildDir);
        }
        elsif($Install)
        {
            if(not check_Cmd($Dep))
            {
                $NotInstalled{$Dep} = 1;
            }
        }
    }
    
    if($Install)
    {
        if(my @ToInstall = keys(%NotInstalled))
        {
            print "\nPlease install also:\n  ".join("\n  ", @ToInstall)."\n\n";
        }
    }
    
    exit(0);
}

scenario();
