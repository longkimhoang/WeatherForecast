.PHONY: install_buck build targets debug clean project

# Use local version of Buck
BUCK = tools/buck

install_buck:
	curl https://jitpack.io/com/github/airbnb/buck/f2865fec86dbe982ce1f237494f10b65bce3d270/buck-f2865fec86dbe982ce1f237494f10b65bce3d270-java11.pex --output tools/buck
	chmod u+x tools/buck

build:
	$(BUCK) build //App:WeatherForecast

build_release:
	$(BUCK) build //App:WeatherForecast --config-file ./BuildConfigurations/Release.buckconfig

debug:
	$(BUCK) install //App:WeatherForecast --run

debug_release:
	$(BUCK) install //App:WeatherForecast --run --config-file ./BuildConfigurations/Release.buckconfig

targets:
	$(BUCK) targets //...

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
