package Email::Assets::File;
use Moose;

=head1 NAME

Email::Assets - Manage assets for Email

=cut

use MIME::Types;
use MIME::Base64 qw(encode_base64 decode_base64);
use MIME::Lite;
use Data::UUID;
use File::Find;
use File::Type;

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
		 writer => '_set_filename',
		);

has mime_type => (
		  is => 'ro',
		  lazy => 1,
		  builder => '_build_mime_type',
		  writer => '_set_mime_type',
		 );

has _has_physical_file => (
			   is => 'ro',
                           isa => 'Int',
			   writer => '_set_has_physical_file',
			 );

has _base64_data => (
		     is => 'ro',
		     writer => '_set_base64_data',
		     predicate => '_has_base64_data',
		   );

sub BUILD {
  my ($self, $args) = @_;
  if ($args->{base64_data}) {
    $self->_set_filename($self->relative_filename);
    $self->_set_has_physical_file(0);
    $self->_set_base64_data($args->{base64_data});
    my $ft = File::Type->new;
    my $magic_string = decode_base64(substr($args->{base64_data},0,30));
    my $mime_type = $ft->mime_type($magic_string);
    $self->_set_mime_type($mime_type);
  } else {
    # check we have valid paths & file
    $self->filename || die "couldn't find path/file";
    $self->_set_has_physical_file(1);
  }
  return ;
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

  if ($self->_has_base64_data) {
    return $self->_base64_data;
  }

  my $filename = $self->filename;
  my $base64 = '';
  my $buf;
  open(FILE, $filename) or die "unable to get file '$filename' : $!";
  while (read(FILE, $buf, 60*57)) {
       $base64 .= encode_base64($buf) . "\n";
  }
  close (FILE);
  $self->_set_base64_data($base64);

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

=head1 ATTRIBUTES

=head2 mime_types - MIME::Types object

=head2 cid

=head2 inline_only - boolean flag, allows you to attach only appropriate assets to a mail

=head2 base_paths - arrayref of where to look for files

=head2 relative_filename - relative path and filename for a file

=head1 METHODS

=head2 filename - full filename and path

=head2 mime_type - MIME or content-type of file

=head2 BUILD - moose method called by constructor, handles validating path to file

=head2 inline_data - method to get file as inline-data string, including content type and base64 encoded file contents

=head2 file_as_base64 - get file contents encoded in base64

=head2 as_mime_part - get file as a MIME::Lite object

=head2 not_inline_only - opposite to inline_only

=head1 AUTHOR

Aaron J Trevena, C<< <teejay at cpan.org> >>

=cut

1;
