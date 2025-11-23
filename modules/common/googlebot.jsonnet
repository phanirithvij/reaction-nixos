// https://reaction.ppom.me/filters/useragent-impersonators.html
local googlebot = (import "/var/lib/reaction/googlebot.json").prefixes;

local isIpv6(obj) =  std.objectHas(obj, "ipv6Prefix");
local isIpv4(obj) =  std.objectHas(obj, "ipv4Prefix");

local toIpv6(obj) = obj.ipv6Prefix;
local toIpv4(obj) = obj.ipv4Prefix;

local ipv6Adresses = std.filterMap(isIpv6, toIpv6, googlebot);
local ipv4Adresses = std.filterMap(isIpv4, toIpv4, googlebot);

local allAdresses = std.flattenArrays([ipv4Adresses, ipv6Adresses]);

local actions = 'ACTIONS';

{
  patterns: {
    // This pattern only matches addresses which does not belong to Google's advertised ranges
    ipnogoogle: {
      type: 'ip',
      ignorecidr: allAdresses,
    },
  },
  streams: {
    nginx: {
      filters: {
        googleimpersonators: {
          regex: [
            @'<ipnogoogle> .* "[^"]*Googlebot[^"]*"$',
          ],
          actions: actions,
        }
      }
    }
  }
}

