requires 'perl', '5.12.0';

requires 'Keyword::Simple';
requires 'PPR';
requires 'Carp';
requires 'Import::Into';
requires 'Data::Lock';
requires 'Type::Tie', '0.010';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

