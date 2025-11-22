// https://reaction.ppom.me/filters/ai-crawlers.html
local aiRobots = import "/var/lib/reaction/ai-robots.json";
local names = std.objectFields(aiRobots);

local nameToRegex(agent) =  @'^<ip>.*"[^"]*' + agent + '[^"]*"$';

local regex = std.map(nameToRegex, names);

local actions = 'ACTIONS';

{
  streams: {
    nginx: {
      filters: {
        gptbot: {
          regex: regex,
          actions: actions,
        }
      }
    }
  }
}

