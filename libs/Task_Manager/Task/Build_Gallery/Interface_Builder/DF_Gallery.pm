package Homyaki::Task_Manager::Task::Build_Gallery::Interface_Builder::DF_Gallery;

use strict;

use XML::Code;
use Net::FTP;
use Homyaki::Logger;

use Homyaki::Task_Manager::Task::Build_Gallery;

use constant WEEK_DAY_MAP => {
	1 => 'Monday',
	2 => 'Tuesday',
	3 => 'Wednesday',
	4 => 'Thursday',
	5 => 'Friday',
	6 => 'Saturday',
	7 => 'Sunday',
};

sub add_xml_string {
	my $xml    = shift;
	my $string = shift;

	my $xml_string       = new XML::Code ('string');
	$xml_string->{id}    = $string;
	$xml_string->{value} = ucfirst($string);
	$xml->add_child($xml_string);
}

sub add_xml_text {
	my $xml  = shift;
	my $name = shift;
	my $text = shift;

	my $xml_value = new XML::Code ($name);
	$xml_value->set_text($text);
	$xml->add_child($xml_value);
}

sub add_xml_config {
	my $xml = shift;

	my $config = new XML::Code ('config');

	add_xml_text($config, 'title'                   , "Hamsters Photos");
	add_xml_text($config, 'thumbnail_dir'           , "images/thumbs/");
	add_xml_text($config, 'image_dir'               , "images/big/");
	add_xml_text($config, 'slideshow_interval'      , "8");
	add_xml_text($config, 'pause_slideshow'         , "true");
	add_xml_text($config, 'rss_scale_images'        , "true");
	add_xml_text($config, 'background_music'        , "gallery1.mp3");
	add_xml_text($config, 'background_music_volume' , "50");
	add_xml_text($config, 'link_images'             , "true");
	add_xml_text($config, 'disable_printscreen'     , "");

	$xml->add_child($config);
}

sub add_xml_album_log {
	my %h = @_;
	
	my $params     = $h{params};
	my $album_tag  = $h{album_tag};

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());

	$wday = &WEEK_DAY_MAP->{$wday};
	$year = 1900 + $year;
	$sec  = sprintf('%02d',$sec);
	$min  = sprintf('%02d',$min);
	$hour = sprintf('%02d',$hour);
	$mday = sprintf('%02d',$mday);
	$mon++;
	$mon  = sprintf('%02d',$mon);


	my $upload_pictures_name = $params->{gallery_path} . "${year}_${mon}_${mday}__${hour}_${min}_${sec}.xml";
	if (open (XML, ">$upload_pictures_name")){

		print XML $album_tag->code();
		close (XML);


		my $ftp = Net::FTP->new($params->{web_path}, Debug => 0)
			or Homyaki::Logger::print_log("DF_Gallery: Error: (Cannot connect to " . $params->{web_path} . ") $@");
		
		$ftp->login($params->{web_login}, $params->{web_password})
			or Homyaki::Logger::print_log("DF_Gallery: Error: (Cannot login to " . $params->{web_path} . ") " . $ftp->message);
	
		upload_file($upload_pictures_name, Homyaki::Task_Manager::Task::Build_Gallery::FTP_PATH, $ftp);
	
		$ftp->quit;
	} else {
		Homyaki::Logger::print_log("DF_Gallery: Error:  can't open $upload_pictures_name file $!");
	}
}

sub upload_file {
	my $source_path = shift;
	my $dest_path   = shift;
	my $ftp         = shift;
	my $index       = 1;
	
	if ($dest_path && $dest_path ne '/') {
		$ftp->put($source_path, $dest_path)
			or Homyaki::Logger::print_log("Build_Gallery: Error: (Cannot put $source_path to $dest_path) " . $ftp->message);
	} else {
		$ftp->put($source_path)
			or Homyaki::Logger::print_log("Build_Gallery: Error: (Cannot put $source_path to $dest_path) " . $ftp->message);
	}
}

sub get_new_album_name {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());

	$wday = &WEEK_DAY_MAP->{$wday};
	$year = 1900 + $year;
	$sec  = sprintf('%02d',$sec);
	$min  = sprintf('%02d',$min);
	$hour = sprintf('%02d',$hour);
	$mday = sprintf('%02d',$mday);
	$mon++;
	$mon  = sprintf('%02d',$mon);

	return "This pictures or comments was changed on $wday $mday.$mon.$year";
}

sub make {
	my $class = shift;
	my %h = @_;

		
	my $params     = $h{params};
	my $albums     = $h{albums};
	my $new_images = $h{new_images};


	my $ftp = Net::FTP->new($params->{web_path}, Debug => 0)
		or die "Cannot connect to some.host.name: $@";
		
	$ftp->login($params->{web_login}, $params->{web_password})
		or die "Cannot login ", $ftp->message;

	my $gallery = new XML::Code ('gallery');
	$gallery->version ('1.0');
	$gallery->encoding ('UTF-8');

	add_xml_config($gallery);

	my $language = new XML::Code ('language');

	add_xml_string($language, "loading");
	add_xml_string($language, "previous page");
	add_xml_string($language, "page % of %");
	add_xml_string($language, "next page");

	my $album_tags = [];
	foreach my $album ({print_log => 1, name => get_new_album_name(), images => $new_images}, (@{$albums})){
		my $image_tags = [];
		foreach my $image (@{$album->{images}}){
			my $image_tag = new XML::Code ('image');
			$image_tag->{title}       = $album->{name};
			$image_tag->{thumbnail}   = $image->{thumbnail};
			$image_tag->{'link'}      = $image->{'link'};
			$image_tag->{image}       = $image->{image};
			$image_tag->{date}        = $image->{date};

			$image_tag->set_text( $image->{resume});
			push(@{$image_tags}, $image_tag);
		}

		if (scalar @{$image_tags} > 0) {

			## Add "Dummy" image at the end of album for stoping auto uploading next albums
			my $image_tag = new XML::Code ('image');
			$image_tag->{title}       = "The End";
	
			$image_tag->{thumbnail}   = "dummy.jpg";
			$image_tag->{image}       = "dummy.jpg";
	
			$image_tag->set_text("'Black square' of Malevich");

			push(@{$image_tags}, $image_tag);

			my $album_tag = new XML::Code ('album');

			$album_tag->{title}       = $album->{name};
			$album_tag->{description} = $album->{name};

			foreach (@{$image_tags}) {
				$album_tag->add_child($_);
			}

			push (@{$album_tags}, $album_tag);
			if  ($album->{print_log}) {
				add_xml_album_log(
					params    => $params,
					album_tag => $album_tag
				)
			}
		}
	}

	my $albums_tag = new XML::Code ('albums');
	foreach (@{$album_tags}) {
		$albums_tag->add_child ($_);
	}

	$gallery->add_child ($albums_tag);
	$gallery->add_child ($language);

	#write to file

	if(open (XML, ">$params->{xml_path}")){
		print XML $gallery->code();
		close (XML);

		my $ftp = Net::FTP->new($params->{web_path}, Debug => 0)
			or Homyaki::Logger::print_log("DF_Gallery: Error: (Cannot connect to " . $params->{web_path} . ") $@");
		
		$ftp->login($params->{web_login}, $params->{web_password})
			or Homyaki::Logger::print_log("DF_Gallery: Error: (Cannot login to " . $params->{web_path} . ") " . $ftp->message);
	
		upload_file($params->{xml_path}, Homyaki::Task_Manager::Task::Build_Gallery::FTP_PATH . '/gallery.xml', $ftp);
	} else {
		Homyaki::Logger::print_log('cant open ' . $params->{xml_path}  . " $!");
	}

	$ftp->quit;
}

1;
