#!perl
use strict;
use Test::More;
use Test::Exception;
use FindBin;

use File::Compare;
use File::Temp;
use MIME::Base64 qw(decode_base64);

use Data::Dumper;
use lib qw(lib/);


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
  is($mime_part->attr("content-type"), 'image/png', 'content type correct');

  my $data_string = $asset->inline_data;
  my ($content_type, $encoding) = $data_string =~ m/(.*?);(.*?),.*/m;
  is($content_type, 'image/png', 'inline data content type correct');
  is($encoding, 'base64', 'inline data encoding type correct');
  my $fh = File::Temp->new();
  my $fname = $fh->filename;
  $data_string =~ s|image/png;base64,||;
  print $fh decode_base64($data_string);
  close $fh;
  ok(compare($fname,$asset->filename) == 0, 'file matches from inline data after decoding');
}

dies_ok( sub { $assets->include($missing_image) }, 'missing image causes fatal error');

done_testing();
