#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 26;

use English '-no_match_vars';
use FindBin;

exit main();

sub main {
	use_ok('Run::Env') or exit;
	
	ok(!Run::Env::debug(),  'we should not be in debug mode');
	ok(Run::Env::testing(), 'we should be in testing mode');
	ok(Run::Env::shell(), 'running from shell');

	diag 'check import()';	
	use_ok('Run::Env', qw( -testing debug production ));

	ok(Run::Env::debug(),        'now debug on');
	ok(!Run::Env::testing(),     'testing off');
	ok(Run::Env::production(),   'production environment');
	ok(!Run::Env::staging(),     'no staging environment');
	ok(!Run::Env::development(), 'no development environment');

	use_ok('Run::Env', qw( development ));
	
	ok(Run::Env::debug(),      'now debug on');
	ok(!Run::Env::testing(),   'testing off');
	ok(Run::Env::development(), 'development environment');

	use_ok('Run::Env', qw( staging ));
	
	ok(Run::Env::staging(),      'no staging environment');


	diag 'execution tests';
	cleanup_env();
	$ENV{'MOD_PERL'} = 1;
	is(Run::Env::detect_execution(), 'mod_perl', 'running under "mod_perl"');

	cleanup_env();
	$ENV{'REQUEST_METHOD'} = 1;
	is(Run::Env::detect_execution(), 'cgi', 'running under as "cgi"');
	
	cleanup_env();
	Run::Env::set_staging();
	Run::Env::set_debug();
	diag 'run bin/print-run-env.pl to get Run::Env';

	my $print_run_env = 'perl '.File::Spec->catfile($FindBin::Bin, 'bin', 'print-run-env.pl');
	my $output = `$print_run_env`;
	
	SKIP: {
		skip 'failed to execute perl test script, skipping tests', 8
			if not $output;
		
		$output =~ s/\s*$//;
		diag 'output: ', $output;
		
		like($output, qr/staging/, 'check env should be staging (from env)');
		like($output, qr/no-testing/, '... no-testing');
		like($output, qr/shell/, '... shell script');
		like($output, qr/\sdebug/, '... and debug');
		
		
		diag 'cleanup env and run it again';
		cleanup_env();
		
		$output = `$print_run_env`;
		$output =~ s/\s*$//;
		diag 'output: ', $output;
		
		like($output, qr/production/, 'should be production now (default)');
		like($output, qr/no-testing/, '... no-testing');
		like($output, qr/shell/, '... shell script');
		like($output, qr/no-debug/, '... and no-debug');
	}
	
	return 0;
}

sub cleanup_env {
	delete $ENV{'RUN-ENV_current'};
	delete $ENV{'RUN-ENV_debug'};
	delete $ENV{'RUN-ENV_testing'};
	delete $ENV{'MOD_PERL'};
	delete $ENV{'REQUEST_METHOD'};
}