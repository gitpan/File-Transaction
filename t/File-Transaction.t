
use strict;
use Test::More tests => 30;

use_ok( 'File::Transaction' );

my $ft = File::Transaction->new;
isa_ok($ft, 'File::Transaction');

string2file("hic hic foo\nbump\n", "t/foo");
$ft->linewise_rewrite("t/foo", sub { s/foo/bar/g });
is_filecont("t/foo.tmp", "hic hic bar\nbump\n", "linewise_rewrite makes t/foo.tmp");

$ft->revert;
ok(! -e "t/foo.tmp", "revert deletes t/foo.tmp");
is_filecont("t/foo", "hic hic foo\nbump\n", "revert leaves t/foo unchanged");

$ft = File::Transaction->new;
string2file("ping foo ping\n", "t/foo");
string2file("pong\n", "t/foo.tmp");
$ft->linewise_rewrite("t/foo", sub { s/foo/bar/g });
is_filecont("t/foo.tmp", "ping bar ping\n", "linewise_rewrite overwrites stale t/foo.tmp");
$ft->commit;
ok(! -e "t/foo.tmp", "commit deletes t/foo.tmp");
is_filecont("t/foo", "ping bar ping\n", "commit updates t/foo");

$ft = File::Transaction->new;
string2file("foo foo foo\n", "t/foo");
string2file("bar bar bar\n", "t/foo.poing");
$ft->addfile("t/foo", "t/foo.poing");
$ft->revert;
ok(! -e "t/foo.poing", "revert after addfile deletes tmpfile");
is_filecont("t/foo", "foo foo foo\n", "revert after addfile leaves t/foo unchanged");

$ft = File::Transaction->new;
string2file("foo foo foo\n", "t/foo");
string2file("bar bar bar\n", "t/foo.poing");
$ft->addfile("t/foo", "t/foo.poing");
$ft->commit;
ok(! -e "t/foo.poing", "commit after addfile deletes tmpfile");
is_filecont("t/foo", "bar bar bar\n", "commit after addfile updates t/foo");

$ft = File::Transaction->new;
unlink "t/foo";
string2file("bar bar bar\n", "t/foo.poing");
$ft->addfile("t/foo", "t/foo.poing");
$ft->revert;
ok(! -e "t/foo.poing", "revert after addfile no oldfile deletes tmpfile");
ok(! -e "t/foo", "revert after addfile no oldfile leaves oldfile absent");

$ft = File::Transaction->new;
unlink "t/foo";
string2file("boing\n", "t/foo.poing");
$ft->addfile("t/foo", "t/foo.poing");
$ft->commit;
ok(! -e "t/foo.poing", "commit after addfile no oldfile deletes tmpfile");
is_filecont("t/foo", "boing\n", "commit after addfile no oldfile updates t/foo");

$ft = File::Transaction->new;
string2file("wump wump foo\n", "t/foo1");
string2file("pong pong foo\n", "t/foo2");
$ft->linewise_rewrite("t/foo1", sub { s/foo/bar/g });
eval { $ft->linewise_rewrite("t/foo2", sub { die "I broke" }); };
like($@, '/I broke/', "linewise_rewrite propagates die");
$ft->revert;
is_filecont("t/foo1", "wump wump foo\n", "revert after die first file unchanged");
is_filecont("t/foo2", "pong pong foo\n", "revert after die second file unchanged");
ok(! -e "t/foo1.tmp", "revert after die first tmpfile removed");
ok(! -e "t/foo2.tmp", "revert after die second tmpfile removed");

$ft = File::Transaction->new;
string2file("wump wump foo\n", "t/foo");
$ft->linewise_rewrite("t/foo", sub { s/foo/bar/g });
eval { $ft->linewise_rewrite("t/x/y/z", sub { s/foo/bar/g }) };
ok($@, "linewise_rewrite dies on file error");
$ft->revert;
is_filecont("t/foo", "wump wump foo\n", "revert after error file unchanged");
ok(! -e "t/foo.tmp", "revert after error tmpfile removed");

$ft = File::Transaction->new;
unlink "t/foo";
$ft->linewise_rewrite("t/foo", sub { die "this sub should never be called" });
$ft->commit;
ok(-e "t/foo" && -s "t/foo" == 0, "linewise_rewrite converts missing to empty");

$ft = File::Transaction->new('baz');
string2file("ding dong foo\n", "t/foo");
$ft->linewise_rewrite("t/foo", sub { s/foo/bar/g });
is_filecont("t/foobaz", "ding dong bar\n", "linewise_rewrite honors tmpext");
$ft->commit;
ok(! -e "t/foobaz", "commit with tmpext deletes tmpfile");
is_filecont("t/foo", "ding dong bar\n", "commit with tmpext updates t/foo");

$ft = File::Transaction->new('bar');
string2file("dong ding foo\n", "t/foo");
$ft->commit;
ok(! -e "t/foobar", "revert with tmpext deletes tmpfile");
is_filecont("t/foo", "dong ding foo\n", "revert with tmpext leaves t/foo unchanged");

unlink "t/foo", "t/foo1", "t/foo2";

sub string2file {
    my ($string, $file) = @_;

    open OUT, ">$file" or die "open >$file: $!";
    print OUT $string;
    close OUT or die "close $file: $!";
}

sub is_filecont {
    my ($filename, $contents, $testname) = @_;

    my $got = undef;
    if (open IN, "<$filename") {
        local $/;
        $got = <IN>;
        close IN;
    }

    is($got, $contents, $testname);
}

