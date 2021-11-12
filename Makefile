.PHONY: install_buck build targets test coverage audit debug clean project

# Use local version of Buck
BUCK = tools/buck

# Simulator name
SIMULATOR_NAME = 'iPhone 8'

install_buck:
	curl https://jitpack.io/com/github/airbnb/buck/f2865fec86dbe982ce1f237494f10b65bce3d270/buck-f2865fec86dbe982ce1f237494f10b65bce3d270-java11.pex --output tools/buck
	chmod u+x tools/buck

build:
	$(BUCK) build //App:WeatherForecast

build_release:
	$(BUCK) build //App:WeatherForecast --config-file ./BuildConfigurations/Release.buckconfig

debug:
	$(BUCK) install //App:WeatherForecast --run --simulator-name $(SIMULATOR_NAME)

debug_release:
	$(BUCK) install //App:WeatherForecast --run --config-file ./BuildConfigurations/Release.buckconfig --simulator-name $(SIMULATOR_NAME)

targets:
	$(BUCK) targets //...

buck_out = $(shell $(BUCK) root)/buck-out
TEST_BUNDLE = $(shell $(BUCK) targets //App:WeatherForecastAppTests --show-output | awk '{ print $$2 }')
test:
	@rm -f $(buck_out)/tmp/*.profraw
	@rm -f $(buck_out)/gen/*.profdata
	$(BUCK) test //App:WeatherForecastAppTests --test-runner-env XCTOOL_TEST_ENV_LLVM_PROFILE_FILE="$(buck_out)/tmp/code-%p.profraw%15x" \
		--config-file code_coverage.buckconfig
	xcrun llvm-profdata merge -sparse "$(buck_out)/tmp/code-"*.profraw -o "$(buck_out)/gen/Coverage.profdata"
	xcrun llvm-cov report "$(TEST_BUNDLE)/WeatherForecastAppTests" -instr-profile "$(buck_out)/gen/Coverage.profdata" -ignore-filename-regex "Vendor|buck-out"

coverage: test
	xcrun llvm-cov show -format=html -output-dir=coverage "$(TEST_BUNDLE)/WeatherForecastAppTests" -instr-profile "$(buck_out)/gen/Coverage.profdata" -ignore-filename-regex "Vendor|buck-out"
	open coverage/index.html

audit:
	$(BUCK) audit rules App/BUCK > Config/Gen/App-BUCK.py

clean:
	rm -rf **/*.xcworkspace
	rm -rf **/*.xcodeproj
	$(BUCK) clean

project: clean
	$(BUCK) project //App:WeatherForecast
	open App/WeatherForecast-BUCK.xcworkspace

dependency_graph:
	$(BUCK) query "deps(//App:WeatherForecast)" --dot > result.dot && dot result.dot -Tpng -o result.png && open result.png
