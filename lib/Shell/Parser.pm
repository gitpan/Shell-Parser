package Shell::Parser;
use strict;
use Carp;
use Text::ParseWords;

{ no strict;
  $VERSION = '0.01';
}

=head1 NAME

Shell::Parser - The great new Shell::Parser!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Shell::Parser;

    my $parser = new Shell::Parser;
    $parser->parse(...);

=head1 DESCRIPTION

This module implements a rudimentary shell parser in Perl. 

=head1 METHODS

=over 4

=item new()

B<Options>

=over 4

=item *

C<handlers> - sets the shell code fragments handlers. 
See L<"handlers()"> for more information. 

=item *

C<syntax> - selects the shell syntax. 
See L<"syntax()"> for more information. 

=back

B<Examples>

    my $parser = new Shell::Parser XXX;

=cut

sub new {
    my $class = shift;
    my $self = {
        handlers => {
            metachar => undef, 
            keyword  => undef, 
            builtin  => undef, 
            command  => undef, 
            assign   => undef, 
            variable => undef, 
            text     => undef, 
            comment  => undef, 
        }, 
        syntax => '', 
    };
    
    $class = ref($class) || $class;
    bless $self, $class;
    
    # treat given arguments
    my %args = @_;
    $args{syntax} ||= 'bourne';
    
    for my $attr (keys %args) {
        $self->$attr($args{$attr}) if $self->can($attr);
    }
    
    return $self
}

=item parse()

=cut

sub parse {
    my $self = shift;
    
    # check argument type
    if(my $ref = ref $_[0]) {
        croak "can't deal with ref of any kind for now"
    }
    
    my $delimiters = join '', @{ $self->{metachars} };
    my @tokens = quotewords('[\s;]+', 'delimiters', $_[0]);
    
    while(my $token = shift @tokens) {
        $token .= shift @tokens if $tokens[0] eq $token;  # e.g: '&','&' => '&&'
        
        my $type = $self->{lookup_hash}{$token} || '';
        $type ||= 'comment'  if index($token, '#') == 0;
        $type ||= 'variable' if index($token, '$') == 0;
        $type ||= 'assign'   if index($token, '=') >= 0;
        $type ||= 'text';
        
        # special processing
        if($type eq 'comment') {
            $token .= shift @tokens while @tokens and index($token, "\n") < 0
        }
        if($type eq 'variable' and index($token, '(') == 1) {
            $token .= shift @tokens while @tokens and index($token, ')') < 0
        }
        
      #print STDERR "type=$type token=<$token> \n";
        &{ $self->{handlers}{$type} }($self, token => $token, type => $type)
    }
}

=item eof()

=cut

sub eof {
    my $self = shift;
}

=item handlers()

Sets the shell code fragments handlers. Available handlers: 

=over 4

=item *

C<assign> - handler for assignments: C<VARIABLE=VALUE>

=item *

C<builtin> - handler for shell builtin commands: C<alias>, C<jobs>, C<read>...

=item *

C<command> - handler for external commands

=item *

C<comment> - handler for comments: C<# an impressive comment>

=item *

C<keyword> - handler for shell reserved words: C<for>, C<if>, C<case>...

=item *

C<metachar> - handler for shell metacharacters: C<;>, C<&>, C<|>...

=item *

C<variable> - handler for variable expansion: C<$VARIABLE>

=item *

C<text> - handler for anything else

=back

There is also a C<default> handler, which will be used for any handler 
which has not been explicitely defined. 

See also L<"Handlers"> for more information on how handlers receive their data. 

=cut

sub handlers {
    my $self = shift;
    my %handlers =  ref $_[0] ? %{$_[0]} : @_;
    
    my $default = undef;
    $default = delete $handlers{default} if $handlers{default};
    
    for my $handler (keys %handlers) {
        carp "No such handler: $handler " and next unless exists $self->{handlers}{$handler};
        $self->{handlers}{$handler} = $handlers{$handler} || $default;
    }
    for my $handler (keys %{$self->{handlers}}) {
        $self->{handlers}{$handler} ||= $default
    }
}

=item syntax()

Selects the shell syntax. Use one of: 

=over 4

=item *

C<bourne> - the standard Bourne shell

=item *

C<csh> - the C shell

=item *

C<tcsh> - the TENEX C shell

=item *

C<korn88> - the Korn shell, 1988 version

=item *

C<korn93> - the Korn shell 1993 version

=item *

C<bash> - GNU Bourne Again SHell

=item *

C<zsh> - the Z shell

=back

Returns the current syntax when called with no argument, or the previous 
syntax when affecting a new one. 

=cut

# Note: 
#  - keywords are the "reserved words" in *sh man pages
#  - builtins are the "builtin commands" in *sh man pages

my %shell_syntaxes = (
    bourne => {
        name => 'Bourne shell', 
        metachars => [ qw{ ; & ( ) | < > } ], 
        keywords => [ qw(
            ! { } case do done elif else esac for if fi in then until while
        ) ], 
        builtins => [ qw(
            alias bg break cd command continue eval exec exit export fc fg 
            getopts hash jobid jobs local pwd read readonly return select 
            set setvar shift trap ulimit umask unalias unset wait
        ) ],
    }, 
    
    csh => {
        name => 'C-shell', 
        keywords => [ qw(
            breaksw case default else end endif endsw foreach if switch then while
        ) ], 
        builtins => [ qw(
            % @ alias alloc bg break cd chdir continue dirs echo eval exec 
            exit fg glob goto hashstat history jobs kill limit login logout 
            nice nohup notify onintr popd pushd rehash repeat set setenv 
            shift source stop suspend time umask unalias unhash unlimit unset 
            unsetenv wait which 
        ) ], 
    }, 
    
    tcsh => {
        name => 'TENEX C-shell', 
        keywords => [ qw(
            breaksw case default else end endif endsw foreach if switch then while
        ) ], 
        builtins => [ qw(
            : % @ alias alloc bg bindkey break builtins bye cd chdir complete 
            continue dirs echo echotc eval exec exit fg filetest getspath 
            getxvers glob goto hashstat history hup inlib jobs kill limit log 
            login logout ls-F migrate newgrp nice nohup notify onintr popd 
            printenv pushd rehash repeat rootnode sched set setenv setpath 
            setspath settc setty setxvers shift source stop suspend telltc 
            time umask unalias uncomplete unhash universe unlimit unset 
            unsetenv ver wait warp watchlog where which 
        ) ], 
    }, 
    
    korn88 => {
        name => 'Korn shell 88', 
        metachars => [ qw{ ; & ( ) | < > } ], 
        keywords => [ qw(
            { } [[ ]] case do done elif else esac fi for function if select 
            time then until while 
        ) ], 
        builtins => [ qw(
            : . alias bg break continue cd command echo eval exec exit export 
            fc fg getopts hash jobs kill let login newgrp print pwd read 
            readonly return set shift stop suspend test times trap type 
            typeset ulimit umask unalias unset wait whence
        ) ], 
    }, 
    
    korn93 => {
        name => 'Korn shell 93', 
        metachars => [ qw{ ; & ( ) | < > } ], 
        keywords => [ qw(
            ! { } [[ ]] case do done elif else esac fi for function if select 
            then time until while 
        ) ], 
        builtins => [ qw(
            : . alias bg break builtin cd command continue disown echo eval 
            exec exit export false fg getconf getopts hist jobs kill let newgrp 
            print printf string pwd read readonly return set shift sleep trap 
            true typeset ulimit umask unalias unset wait whence 
        ) ], 
    }, 
    
    bash => {
        name => 'Bourne Again SHell', 
        metachars => [ qw{ ; & ( ) | < > } ], 
        keywords => [ qw(
            ! { } [[ ]] case do done elif else esac fi for function if in 
            select then time until while 
        ) ], 
        builtins => [ qw(
            : . alias bg bind break builtin cd command compgen complete 
            continue declare dirs disown echo enable eval exec exit export 
            fc fg getopts hash help history jobs kill let local logout popd 
            printf pushd pwd read readonly return set shift shopt source 
            suspend test times trap type typeset ulimit umask unalias unset 
            wait
        ) ], 
    }, 
    
    zsh => {
        name => 'Z shell', 
        metachars => [ qw{ ; & ( ) | < > } ], 
        keywords => [ qw(
            ! { } [[ case coproc do done elif else end esac fi for foreach 
            function if in nocorrect repeat select then time until while 
        ) ], 
        builtins => [ qw(
            : . [ alias autoload bg bindkey break builtin bye cap cd chdir 
            clone command comparguments compcall compctl compdescribe compfiles 
            compgroups compquote comptags comptry compvalues continue declare 
            dirs disable disown echo echotc echoti emulate enable eval exec 
            exit export false fc fg float functions getcap getln getopts hash 
            history integer jobs kill let limit local log logout noglob popd 
            print pushd pushln pwd r read readonly rehash return sched set 
            setcap setopt shift source stat suspend test times trap true ttyctl 
            type typeset ulimit umask unalias unfunction unhash unlimit unset 
            unsetopt vared wait whence where which zcompile zformat zftp zle 
            zmodload zparseopts zprof zpty zregexparse zstyle
        ) ], 
    }, 
);

sub syntax {
    my $self = shift;
    my $old = $self->{syntax};
    my $syntax = $self->{syntax} = $_[0] if $_[0];
    
    if($syntax ne $old) {
        # (re)initialize the lookup hash when the syntax given in argument 
        # is different from the syntax we already had
        $self->{lookup_hash} = {};
        $self->{metachars} = [ @{ $shell_syntaxes{$syntax}{metachars} } ];
        
        for my $type (qw(keyword builtin)) {
            my @words = @{ $shell_syntaxes{$syntax}{"${type}s"} };
            @{ $self->{lookup_hash} }{@words} = ($type) x scalar @words;
        }
    }
    
    return $self->{syntax}
}

=back

=head1 HANDLERS

To be written. 

    sub handler {
        my $self = shift;
        my %args = @_;
        
        # do stuff
        # ...
    }

=head1 AUTHOR

Sébastien Aperghis-Tramoni, E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-shell-parser@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Sébastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Shell::Parser
