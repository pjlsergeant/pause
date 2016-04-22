package pause_1999::Test::Fixtures::Author;

use Moose;

has 'environment' => (
    is       => 'ro',
    isa      => 'pause_1999::Test::Environment',
    weak_ref => 1,
);

has [qw/username asciiname/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'password_crypted' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_password_crypted {
    my $self = shift;
    return crypt( $self->password, 'zz' );
}

has 'fullname' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_fullname { $_[0]->asciiname }

has 'password' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { rand(999) },
);

has 'ustatus' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'active',
);

has 'ugroup' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

sub BUILD {
    my $self = shift;

    my $usertable = $self->environment->authen_dbh->prepare( "
        INSERT INTO usertable (user, password)
        VALUES (?, ?)
    " );
    $usertable->execute( $self->username, $self->password_crypted );

    my $grouptable = $self->environment->authen_dbh->prepare( "
        INSERT INTO grouptable (user, ugroup)
        VALUES (?, ?)
    " );
    for my $ugroup ( @{ $self->ugroup } ) {
        $grouptable->execute( $self->username, $ugroup );
    }

    my $mod_users = $self->environment->mod_dbh->prepare( "
        INSERT INTO users (userid, ustatus, fullname, asciiname)
        VALUES (?, ?, ?, ?)
    " );
    $mod_users->execute(
        $self->username, $self->ustatus,
        $self->fullname, $self->asciiname
    );
}

sub req {
    my ( $self, $req ) = @_;
    $req->headers->authorization_basic( $self->username, $self->password );
    return $req;
}

1;
