#!/usr/bin/perl

$css_file = shift @ARGV;

open FILE, $css_file;

$full = "";
foreach $line (<FILE>){
	chomp($line);
	$line =~ s/[ \t]+/ /g;
	$full .= $line;
}

$full =~ s#/\*.*?\*/##g; #remove comments
#print $full;
@stuff = split(/\{|\}/, $full);

$stylesheet = {};
$reverse = {};
@directions = ("-top","-right", "-bottom", "-left");
for($i=0; $i<scalar @stuff; $i++) {
	@selectors = split(/ *, */, $stuff[$i]);
	@rules = split(/ *; */, $stuff[++$i]); #danger line, this is incrementing $i :-P
#	@rules = expand_rules(\@rules);
	$rule_tokens= {};
	

	foreach $rule (@rules){
		@parts = split(/ *: */, $rule);
		$parts[0] =~ s/ //g;

		if($parts[0] eq "padding" || $parts[0] eq "margin")
		{
			@bits = split(/ /,$parts[1]);
			@lots_bits = (@bits, @bits, @bits, @bits);
			for($j=0; $j<4; $j++)
			{
				#print "Foo".$parts[0].$directions[$j]."\n";
				$rule_tokens->{$parts[0].$directions[$j]} = $lots_bits[$j];
			}
			next; 
		}

		$rule_tokens->{$parts[0]} = $parts[1];

		foreach $selector (@selectors){
			$reverse->{$parts[0].': '.$parts[1]}->{$selector} = 1;
		}
	}

	foreach $selector (@selectors){
		@parts = split(/ /, $selector);
		$eval_str = '$stylesheet';
		foreach $part (@parts){
			$eval_str .= "->{'$part'}";
		}
		$eval_str .= '->{"rules"} = $rule_tokens;';
	#	print $eval_str,"\n";
		eval($eval_str);
	}		
}

print_rules($stylesheet, "");
print_reindexed_rules();
sub print_rules {
	my ( $rules_ref, $rule_string ) = @_;

	foreach $key (keys %{$rules_ref}) 
	{
		if( $key ne "rules") 
		{
			print_rules($rules_ref->{$key}, $rule_string.$key.' ');
			next;
		}	

		print $rule_string."{\n";
		foreach $rule (keys %{$rules_ref->{"rules"}}) 
		{
			print "\t".$rule.': '.$rules_ref->{"rules"}->{$rule}.";\n";
		}
		print "}\n\n";

		#if( scalar keys %{$rules_ref} ) { $rule_string = ""; } 
	}
}

sub print_reindexed_rules {
	foreach $rule (keys %{$reverse})
	{
		foreach $selector (keys %{$reverse->{$rule}})
		{
			print STDERR $selector.", ";
		}
		print STDERR " {\n\t$rule;\n}\n\n";
	}
}

#padding margin border background
sub expand_rules {
	my ( $rules_ref )= @_;
	@rules = @{$rules_ref};

	@final_rules = ();

	for(my $i=0; $i< scalar @rules; $i++) {
		print $rules[$i]."foo\n";
		$rules[$i] =~ s/ //g;
		if($rules[$i] eq "padding")
		{
			@bits = split(/ /,$rules[++$i]);
			@lots_bits = (@bits, @bits, @bits, @bits);
			for($j=0; $j<3; $j++)
			{
				push @final_rules, ($rules[$i].$directions[$j], $lots_bits[$j]);
			}
			next; 
		}
		push @final_rules, ($rules[$i], $rules[++$i]);
	}
	return @final_rules;
}

use Data::Dumper;

#print Dumper($stylesheet);
#print STDERR Dumper($reverse);

