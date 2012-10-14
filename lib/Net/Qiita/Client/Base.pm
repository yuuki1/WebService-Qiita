package Net::Qiita::Client::Base;
use strict;
use warnings;
use utf8;

use Carp qw(croak);
use LWP::UserAgent;
use JSON;
use HTTP::Response;
use URI;

use Class::Accessor::Lite (
    rw => [qw(
        url_name
        password
        token
    )],
);

use constant {
    ROOT_URL    => 'https://qiita.com',
    PREFIX_PATH => '/api/v1',
};

sub agent {
    my $self = shift;
    my $options = {
        ssl_opts => { verify_hostname => 0 },
        timeout  => 10,
    };
    $self->{agent} ||= LWP::UserAgent->new(%$options);
}

sub get {
    my ($self, $path, $params) = @_;
    $self->_request('GET', $path, $params);
}

sub post {
    my ($self, $path, $params) = @_;
    $self->_request('POST', $path, $params);
}

sub put {
    my ($self, $path, $params) = @_;
    $self->_request('PUT', $path, $params);
}

sub delete {
    my ($self, $path, $params) = @_;
    $self->_request('DELETE', $path, $params);
}

sub _request {
    my ($self, $method, $path, $params) = @_;

    my $url = ROOT_URL . PREFIX_PATH . $path;
    $params->{token} = $self->token if $self->token;

    my $uri = URI->new($url);
    my $request = HTTP::Request->new("$method" => $uri->as_string);
    $request->content_type('application/json');
    $uri->query_form(%$params);
    if ($method eq 'GET' || $method eq 'DELETE') {
        $request->uri($uri->as_string);
    } elsif ($method eq 'POST' || $method eq 'PUT') {
        $request->content($uri->query);
    } else {
        croak "invalid http method: $method";
    }
    my $response = agent->request($request);
    croak _error_message($response, $method, $url) if $response->is_error;

    $response->content ? JSON::decode_json($response->content) : "";
}

sub _error_message {
    my ($response, $method, $url) = shift;

    my $content = $response->content;
    if ($content) {
        my $json = JSON::decode_json($content);
        return $json->{error} if $json->{error};
    }
    sprintf "%s %s: %d", $method, $url, $response->code;
}

1;
