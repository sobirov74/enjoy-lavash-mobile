export const yandexGeocoder = ({
enabled = true,
geocode,
uri,
}: AddressByLatParams) => {
return useQuery({
queryKey: ["get_addresses_by_lat", geocode, uri],
queryFn: () => {
return axios
.get(
`https://geocode-maps.yandex.ru/1.x/?apikey=${getAPIKey(
            geocoderApiKey
          )}&geocode=${geocode?.join(",")}&format=json&lang=uz`,
{ params: { uri } }
)
.then(({ data }: GeocoderTypes) => {
const geocodeResult: { name: string } =
data?.response?.GeoObjectCollection?.featureMember?.[0]?.GeoObject;
const request =
data?.response?.GeoObjectCollection?.featureMember?.[0]?.GeoObject?.Point?.pos?.split(
" "
);
const district =
data?.response?.GeoObjectCollection?.featureMember?.find(
(element) => element.GeoObject?.name?.includes("tuman") || false
)?.GeoObject?.name || "";
// const district =
// data?.response?.GeoObjectCollection?.featureMember?.[2]?.GeoObject
// ?.metaDataProperty?.GeocoderMetaData?.AddressDetails?.Country
// ?.AdministrativeArea?.Locality?.DependentLocality
// ?.DependentLocalityName;
return {
name: geocodeResult?.name,
district,
coords: !!uri ? request : geocode,
};
});
},
enabled,
});
};

export const yandexSuggestions = ({
enabled = true,
searchAdr,
}: {
enabled?: boolean;
searchAdr?: string;
}) => {
// const lang = getCookie("NEXTAPP_LOCALE");
return useQuery({
queryKey: ["get_addresses_by_text", searchAdr],
queryFn: ({ signal }) =>
axios
.get(
`https://suggest-maps.yandex.ru/v1/suggest?apikey=${getAPIKey(
            suggestApiKey
          )}&text=${searchAdr}&print_address=1&attrs=uri&lang=${"ru"}`,
{ signal }
)
.then(({ data }: any) => {
return data?.results as AddresseSuggestionType[];
}),
enabled,
});
};

export interface AddresseSuggestionType {
title: {
text: string;
hl: [
{
begin: number;
end: number;
}
];
};
subtitle: {
text: string;
};
tags: string[];
distance: {
value: number;
text: string;
};
uri?: string;
}

export interface AddressByLatParams {
enabled?: boolean;
geocode?: any;
uri?: string;
}

export interface GeocoderTypes {
data: {
response: {
GeoObjectCollection: {
metaDataProperty: {
GeocoderResponseMetaData: {
Point: {
pos: string;
};
request: string;
results: string;
found: string;
};
};
featureMember: [
{
GeoObject: {
metaDataProperty: {
GeocoderMetaData: {
precision: string;
text: string;
kind: string;
Address: {
country_code: string;
formatted: string;
Components: [
{
kind: string;
name: string;
},
{
kind: string;
name: string;
},
{
kind: string;
name: string;
},
{
kind: string;
name: string;
},
{
kind: string;
name: string;
}
];
};
AddressDetails: {
Country: {
AddressLine: string;
CountryNameCode: string;
CountryName: string;
AdministrativeArea: {
AdministrativeAreaName: string;
Locality: {
LocalityName: string;
Thoroughfare: {
ThoroughfareName: string;
Premise: {
PremiseNumber: string;
};
};
};
};
};
};
};
};
name: string;
description: string;
boundedBy: {
Envelope: {
lowerCorner: string;
upperCorner: string;
};
};
uri: string;
Point: {
pos: string;
};
};
},
{
GeoObject: {
metaDataProperty: {
GeocoderMetaData: {
precision: string;
text: string;
kind: string;
Address: {
country_code: string;
formatted: string;
Components: [
{
kind: string;
name: string;
},
{
kind: string;
name: string;
},
{
kind: string;
name: string;
},
{
kind: string;
name: string;
}
];
};
AddressDetails: {
Country: {
AddressLine: string;
CountryNameCode: string;
CountryName: string;
AdministrativeArea: {
AdministrativeAreaName: string;
Locality: {
LocalityName: string;
Thoroughfare: {
ThoroughfareName: string;
};
};
};
};
};
};
};
name: string;
description: string;
boundedBy: {
Envelope: {
lowerCorner: string;
upperCorner: string;
};
};
uri: string;
Point: {
pos: string;
};
};
},
{
GeoObject: {
metaDataProperty: {
GeocoderMetaData: {
precision: string;
text: string;
kind: string;
Address: {
country_code: string;
formatted: string;
Components: [
{
kind: string;
name: string;
},
{
kind: string;
name: string;
},
{
kind: string;
name: string;
},
{
kind: string;
name: string;
},
{
kind: string;
name: string;
}
];
};
AddressDetails: {
Country: {
AddressLine: string;
CountryNameCode: string;
CountryName: string;
AdministrativeArea: {
AdministrativeAreaName: string;
Locality: {
LocalityName: string;
DependentLocality: {
DependentLocalityName: string;
DependentLocality: {
DependentLocalityName: string;
};
};
};
};
};
};
};
};
name: string;
description: string;
boundedBy: {
Envelope: {
lowerCorner: string;
upperCorner: string;
};
};
uri: string;
Point: {
pos: string;
};
};
},
{
GeoObject: {
metaDataProperty: {
GeocoderMetaData: {
precision: string;
text: string;
kind: string;
Address: {
country_code: string;
formatted: string;
Components: [
{
kind: string;
name: string;
},
{
kind: string;
name: string;
},
{
kind: string;
name: string;
},
{
kind: string;
name: string;
}
];
};
AddressDetails: {
Country: {
AddressLine: string;
CountryNameCode: string;
CountryName: string;
AdministrativeArea: {
AdministrativeAreaName: string;
Locality: {
LocalityName: string;
DependentLocality: {
DependentLocalityName: string;
};
};
};
};
};
};
};
name: string;
description: string;
boundedBy: {
Envelope: {
lowerCorner: string;
upperCorner: string;
};
};
uri: string;
Point: {
pos: string;
};
};
},
{
GeoObject: {
metaDataProperty: {
GeocoderMetaData: {
precision: string;
text: string;
kind: string;
Address: {
country_code: string;
formatted: string;
Components: [
{
kind: string;
name: string;
},
{
kind: string;
name: string;
},
{
kind: string;
name: string;
}
];
};
AddressDetails: {
Country: {
AddressLine: string;
CountryNameCode: string;
CountryName: string;
AdministrativeArea: {
AdministrativeAreaName: string;
Locality: {
LocalityName: string;
};
};
};
};
};
};
name: string;
description: string;
boundedBy: {
Envelope: {
lowerCorner: string;
upperCorner: string;
};
};
uri: string;
Point: {
pos: string;
};
};
},
{
GeoObject: {
metaDataProperty: {
GeocoderMetaData: {
precision: string;
text: string;
kind: string;
Address: {
country_code: string;
formatted: string;
Components: [
{
kind: string;
name: string;
},
{
kind: string;
name: string;
}
];
};
AddressDetails: {
Country: {
AddressLine: string;
CountryNameCode: string;
CountryName: string;
AdministrativeArea: {
AdministrativeAreaName: string;
};
};
};
};
};
name: string;
description: string;
boundedBy: {
Envelope: {
lowerCorner: string;
upperCorner: string;
};
};
uri: string;
Point: {
pos: string;
};
};
},
{
GeoObject: {
metaDataProperty: {
GeocoderMetaData: {
precision: string;
text: string;
kind: string;
Address: {
country_code: string;
formatted: string;
Components: [
{
kind: string;
name: string;
},
{
kind: string;
name: string;
}
];
};
AddressDetails: {
Country: {
AddressLine: string;
CountryNameCode: string;
CountryName: string;
AdministrativeArea: {
AdministrativeAreaName: string;
};
};
};
};
};
name: string;
description: string;
boundedBy: {
Envelope: {
lowerCorner: string;
upperCorner: string;
};
};
uri: string;
Point: {
pos: string;
};
};
},
{
GeoObject: {
metaDataProperty: {
GeocoderMetaData: {
precision: string;
text: string;
kind: string;
Address: {
country_code: string;
formatted: string;
Components: [
{
kind: string;
name: string;
}
];
};
AddressDetails: {
Country: {
AddressLine: string;
CountryNameCode: string;
CountryName: string;
};
};
};
};
name: string;
boundedBy: {
Envelope: {
lowerCorner: string;
upperCorner: string;
};
};
uri: string;
Point: {
pos: string;
};
};
}
];
};
};
};
}

const getAPIKey = (keys: string[]) => {
return keys[Math.floor(Math.random() * keys.length)];
};

export const geocoderApiKey = [
"b95528c3-8d5d-481c-a549-e5b760c57e74", // my
];
export const suggestApiKey = [
"0eb8dc58-f9d3-4df8-8cee-1af2c1c083f7",
];
