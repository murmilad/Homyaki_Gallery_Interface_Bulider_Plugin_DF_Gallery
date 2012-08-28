package Homyaki::Interface::Gallery::DF_Gallery;

use strict;

use Data::Dumper;

use Homyaki::Tag;
use Homyaki::HTML;
use Homyaki::HTML::Constants;

use Homyaki::Logger;

use Homyaki::Interface;
use base 'Homyaki::Interface::Gallery';

use constant PARAMS_MAP  => {
};

sub get_form {
	my $self = shift;
	my %h = @_;

	my $params   = $h{params};
	my $errors   = $h{errors};
	my $user     = $h{user};
	my $body_tag = $h{body_tag};

	my $root = $self->SUPER::get_form(
		params   => $params,
		errors   => $errors,
		form_id  => 'blog_form',
		body_tag => $body_tag,
	);

	my $root_tag = $root->{root};
	my $body_tag_ = $root->{body};

	my $permissions = $user->{permissions};


	if (-f &WWW_PATH . '/gallery.html') {
		if (open HTML_FILE, '<' . &WWW_PATH . '/gallery.html') {
			my $html_file = '';
			while (my $str = <HTML_FILE>) {
				$html_file .= $str;
			}
			close HTML_FILE;

			$body_tag_->add_form_element(
				name   => "html_body",
				type   => &INPUT_TYPE_DIV,
				body   => $html_file,
			);
			
		}
	}


	my $body_tag = $h{body_tag};

	return {
		root => $root_tag,
		body => $body_tag_,
	};
}

1;
