window.vizareGeocodeAddress = function (address) {
  return new Promise(function (resolve, reject) {
    const geocoder = new google.maps.Geocoder();
    geocoder.geocode({ address: address }, function (results, status) {
      if (status !== "OK" || !results || !results.length) {
        reject(new Error("Location could not be found: " + status));
        return;
      }
      const result = results[0];
      resolve(JSON.stringify({
        latitude: result.geometry.location.lat(),
        longitude: result.geometry.location.lng(),
        name: result.formatted_address
      }));
    });
  });
};

window.vizareReverseGeocode = function (latitude, longitude) {
  return new Promise(function (resolve, reject) {
    const geocoder = new google.maps.Geocoder();
    geocoder.geocode(
      { location: { lat: latitude, lng: longitude } },
      function (results, status) {
        if (status !== "OK" || !results || !results.length) {
          reject(new Error("Address could not be found: " + status));
          return;
        }
        resolve(JSON.stringify({ name: results[0].formatted_address }));
      }
    );
  });
};
