use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Shell::Parser',
    AUTHOR              => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Shell/Parser.pm',
    ABSTRACT_FROM       => 'lib/Shell/Parser.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Shell-Parser-*' },
);
