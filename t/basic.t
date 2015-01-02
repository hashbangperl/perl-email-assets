#!perl
use strict;
use Test::More;
use Test::Exception;
use FindBin;

use Data::Dumper;
use lib qw(lib/);

use File::Compare;
use Email::Assets;

my @test_paths = map { $FindBin::Bin . '/'. $_ } qw(aa bb cc);

my $existing_image = 'aa/test.png';
my $existing_textfile = 'bb/test.txt';
my $missing_image = 'bb/foo.gif';

my $assets = Email::Assets->new( base => [ @test_paths ] );

# Email::Assets will automatically detect the type based on the extension
my $asset = $assets->include($existing_image);

# This asset won't get attached twice, as Email::Assets will ignore repeats of a path
my $cid = $assets->include($existing_image)->cid;

is ($cid, $asset->cid, 'cid matches for same image');

# Or you can iterate (in order)
for my $asset ($assets->exports) {
  my $mime_part = $asset->as_mime_part;
  isa_ok($mime_part, 'MIME::Lite');
  is('image/png', $mime_part->attr("content-type"), 'content type correct');
#  warn Dumper(part => $mime_part);
}

dies_ok( sub { $assets->include($missing_image) }, 'missing image causes fatal error');

done_testing();
