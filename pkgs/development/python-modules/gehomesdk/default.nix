{ lib
, aiohttp
, bidict
, buildPythonPackage
, fetchPypi
, humanize
, lxml
, pythonOlder
, requests
, setuptools
, slixmpp
, websockets
}:

buildPythonPackage rec {
  pname = "gehomesdk";
  version = "0.5.27";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-H76y784lYzETgq5XSsQOSGka/kvM+hyMHzUHEJuXTuk=";
  };

  nativeBuildInputs = [
    setuptools
  ];

  propagatedBuildInputs = [
    aiohttp
    bidict
    humanize
    lxml
    requests
    slixmpp
    websockets
  ];

  # Tests are not shipped and source is not tagged
  # https://github.com/simbaja/gehome/issues/32
  doCheck = false;

  pythonImportsCheck = [
    "gehomesdk"
  ];

  meta = with lib; {
    description = "Python SDK for GE smart appliances";
    mainProgram = "gehome-appliance-data";
    homepage = "https://github.com/simbaja/gehome";
    changelog = "https://github.com/simbaja/gehome/blob/master/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
