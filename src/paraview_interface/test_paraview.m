function tests = test_paraview()
tests = functiontests(localfunctions);
end


function test_check_install(testCase)

pv = Paraview(Settings("examples/cli/res/cli_settings.json"));
verifyTrue(testCase, pv.check_conda_installation());

end


function test_check_open(testCase)

pv = Paraview(Settings("examples/cli/res/cli_settings.json"));
pv.open();
verifyTrue(testCase, true);

end