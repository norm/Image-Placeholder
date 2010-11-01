Image Placeholder
=================
A library, command-line script and website for generating placeholder images.
See [ima.gs][] for the online version that uses this code.


p5-Image-Placeholder
--------------------
Perl library, available from [CPAN][]. Comes with a command-line script, used
like so:

    placeholder --background-color=999 400x300 > test.png

To install this, you will need to be running perl (at least 5.10), and to
install it either using the standard `cpan` command, or better yet [cpanm][]
like so:

    cpanm --sudo Image::Placeholder


Deploying as a website
----------------------
If you want to run your own installation of this:

* inside your corporate firewall so as not to leak HTTP_REFERER values out into the internet
* within a [fort][] or other structure without internet access
* on your laptop
* as another competitor in the highly lucrative online placeholder market

you will need to be running perl (at least 5.10), and to install a bunch
of modules from cpan. I'd recommend using [cpanm][], like so:

    cpanm --sudo                                \
        Modern::Perl                            \
        GD                                      \
        Plack                                   \
        Plack::Middleware::Expires              \
        Moose                                   \
        MooseX::FollowPBP                       \
        MooseX::Method::Signatures

Once those are installed, clone this repository, `cd` into it and run the
command:

    plackup -Ilib placeholder.psgi

which will run it on port 5000.

Check the [Plack][] website for more information on the various ways of
deploying Plack powered websites.



[ima.gs]: http://ima.gs/
[CPAN]:   http://search.cpan.org/dist/Image-Placeholder/
[fort]:   http://devfort.com/
[cpanm]:  http://cpanmin.us/
[Plack]:  http://plackperl.org/
