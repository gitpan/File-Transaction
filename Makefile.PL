use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'File::Transaction',
    'VERSION_FROM' => 'Transaction.pm',
    'PREREQ_PM'    => {
                        'Test::More' => 0,
                        'IO::File'   => 0,
                      },
);

