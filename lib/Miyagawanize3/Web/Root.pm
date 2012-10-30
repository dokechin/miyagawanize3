package Miyagawanize3::Web::Root;
use Mojo::Base 'Mojolicious::Controller';
use Imager;
use MIME::Base64;
use Image::ObjectDetect;

my $cascade  = './haarcascade_frontalface_alt2.xml';
my $detector = Image::ObjectDetect->new($cascade);

# This action will render a template
sub convert {
  my $self = shift;
  # Uploaded image(Mojo::Upload object)
  my $image = $self->req->upload('file');
  # Check file type
  my $image_type = $image->headers->content_type;
  my %valid_types = map {$_ => 1} qw(image/gif image/jpeg image/png);
 
 print $image_type;
  # Content type is wrong
  unless ($valid_types{$image_type}) {
      return $self->render(
          template => 'error',
          message  => "Upload fail. Content type is wrong."
      );
  }
 
  # Extention
  my $exts = {'image/gif' => 'gif', 'image/jpeg' => 'jpeg',
              'image/png' => 'png'};
  my $ext = $exts->{$image_type};
  my $filename = "data/" . $image->filename;
  $image->move_to($filename );
  my $imager = Imager->new( file => $filename , type => $ext )               
      or die Imager->errstr;

  my $purple_source = Imager->new->read( file => './purple.png' ) or die Imager->errstr;
  my @faces = $detector->detect($filename );
  my $aspect = 1.5;
  for my $face (@faces) {
     my $purple = $purple_source->scale(
         xpixels => $face->{width} / $aspect,
         ypixels => $face->{height} / $aspect,
     );
     $imager->rubthrough(
         tx  => $face->{width} / $aspect / 2 + $face->{x},
         ty  => $face->{height} / $aspect + $face->{y},
         src => $purple,
     );
  }

  my $newdata;
  $imager->write( data => \$newdata, type => $ext ) or die $imager->errstr;
  my $base64 = encode_base64( $newdata, '' );
  $self->render_text("data:$image_type;base64,$base64");
}
1;