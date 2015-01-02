package Email::Assets::File;
use Moose;

use MIME::Types;

has _mime_types => (
		    is => 'ro',
		    lazy => 1,
		    default => sub { return MIME::Types->new(); },
);

has cid => (
	    is => 'ro',
	   );

has relative_path => (
		      is => 'ro',
		      required => 1,
		     );

has filename => (
		 is => 'ro',
		);

has mime_type => (
		  is => 'ro',
		 );

sub _build_mime_type {
  my $self = shift;
  my $mime_type = $self->_mime_types->mimeTypeOf($self->filename);
  return $mime_type;
}

1;
