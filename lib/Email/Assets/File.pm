package Email::Assets::File;
use Moose;

use MIME::Types;
use MIME::Base64 qw(encode_base64);
use MIME::Lite;
use Data::UUID;
use File::Find;

has mime_types => (
		    is => 'ro',
		    lazy => 1,
		    default => sub { return MIME::Types->new(); },
);

has cid => (
	    is => 'ro',
            lazy => 1,
	    builder => '_build_cid',
	   );

has inline_only => (
		    is => 'rw',
);

has base_paths => (
		   is      => 'ro',
		   required => 1,
		  );

has relative_filename => (
		      is => 'ro',
		      required => 1,
		     );

has filename => (
		 is => 'ro',
		 lazy => 1,
		 builder => '_build_filename',
		);

has mime_type => (
		  is => 'ro',
		  lazy => 1,
		  builder => '_build_mime_type',

		 );

sub BUILD {
  my $self = shift;
  # check we have valid paths & file
  $self->filename || die "couldn't find path/file";
}

sub inline_data {
  my $self = shift;
  my $inline_data_string = sprintf('%s;base64,%s',
				   $self->mime_type,
				   $self->file_as_base64
				  );
  return $inline_data_string;
}

sub file_as_base64 {
  my $self = shift;
  my $filename = $self->filename;
  my $base64 = '';
  my $buf;
  open(FILE, $filename) or die "unable to get file '$filename' : $!";
  while (read(FILE, $buf, 60*57)) {
       $base64 .= encode_base64($buf) . "\n";
  }
  close (FILE);
  return $base64;
}

sub as_mime_part {
    my $self = shift;
    my $part = MIME::Lite->new( Type => $self->mime_type,
			     Filename => $self->filename,
			     Id => $self->cid,
	);
    return $part;
}

sub not_inline_only {
  return not shift()->inline_only;
}

####


sub _build_mime_type {
  my $self = shift;
  my $mime_type = $self->mime_types->mimeTypeOf($self->filename);
  return $mime_type;
}

sub _build_cid {
    return Data::UUID->new->create_str;
}

sub _build_filename {
  my $self = shift;
  my $file = $self->relative_filename;
  if ($file =~ m|^\/|) {
    die "no file exists at absolute path $file" unless (-e $file);
    return $file;
  }
  my $matching_filename = '';
  eval {
    find(sub {
	   if ($File::Find::name =~ m|\/$file$|) {
	     $matching_filename = $File::Find::name;
	     die "matched";
	   }
	 }, @{$self->base_paths});
  };
  unless ($matching_filename) {
    die "no matching file $file in search paths : ", join (', ',@{$self->base_paths});
  }
  return $matching_filename;

}

1;
