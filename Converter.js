const fs = require('fs');
let Jimp;
try {
    Jimp = require('jimp');
} catch (e) {
    Jimp = null;
}
if (Jimp === null) {
    const { spawnSync } = require('child_process');
    console.warn("Jimp is not available trying to install.")
    const result = spawnSync('npm.cmd', ['install', "jimp"]);
    if (result.error) {
        console.error(`Error installing Jimp: ${result.error.message}. Please install Jimp manually.`);
        return;
    } else {console.log(`Successfully installed Jimp! Please restart the program.`); return;}
}


let filename = "";
let texturesDir = "";
let outputDir = "";
let converted = {
    "properties": {
        "label": {
            "displayText" : "",
            "position" : {
                "x": 0,
                "y": 0,
                "z": 0
            },
            "rotation": {
                "pitch" : 0, 
                "roll" : 0, 
                "jaw" : 0
            }
        },
    },
    "cubes" : [],
    "groups" : []
};

if (process == null) { return; }
skipnext = false;
let args = process.argv.slice(2);
if (args.length < 1 || args[0] == "-help") {
    console.log("Usage:");
    console.log(" -f <file> The json file to convert.");
    console.log(" -t <folder> The folder to get the textures from.");
    console.log(" -o <folder> The folder to output the converted json file.");
    console.log(" -l <string> The label of the hologram to display in game.");
}
args.forEach(function (val, index, array) {
    if (!skipnext) {
    val = val.toLowerCase();
    switch (val) {
        case "-f":
        case "-file":
        case "-json":
        case "-model":
            skipnext = true;
            filename = args[index+1]
            break;
        case "-t":
        case "-textures":
        case "-resources":
        case "-texturesDir":
            skipnext = true;
            texturesDir = args[index+1];
            break;
        case "-o":
        case "-out":
        case "-output":
        case "-outputDir":
            skipnext = true;
            outputDir = args[index+1];
            break;
        case "-l":
        case "-label":
            skipnext = true;
            converted.label.displayText = args[index+1];
            break;
    }
    } else { skipnext = false;}
});
if (texturesDir == "") { texturesDir = __dirname; }
if (outputDir == "") { outputDir = __dirname}

let model = JSON.parse(fs.readFileSync(filename));
if (model == null) { console.error("Model not found. Use -help."); return; }

let textureFiles = fs.readdirSync(texturesDir);
if (textureFiles == []) { console.error("Textures directory is empty. Use -help."); return; }
let textures = model.textures;
for (let key in textures) {
    textures[key] = textures[key].slice(textures[key].lastIndexOf("/")+1)
}
let left = Object.keys(textures).length;

textureFiles.forEach((file) => {
    for (let key in textures) {
        if (file == textures[key]+".png") {
            left -= 1;
        }
    }
});
if (left != 0) { console.error("Couldn't find textures. "+left+" missing. Use -help."); return; }

function getTextureByKey(key) {
    for (let id in textures) {
        if (id == key) {
            return textures[key];
        }
    }
}

async function getPixelColor(filePath, x, y) {
    const start = new Date()
    try {
      const image = await Jimp.read(filePath);
      const color = image.getPixelColor(x, y).toString(16).padStart(8, '0');
      return color;
    } catch (error) {
      console.error('Error:', error.message);
      return null;
    }
}

model.elements.forEach(async function(element, key, array) {
    let cube = {};
    let face = element.faces.north;
    cube.color = await getPixelColor(texturesDir+"\\"+getTextureByKey(face.texture.slice(1))+".png", face.uv[0], face.uv[1]);
    /*cube.rotation = {"pitch" : 0, "roll" : 0, "jaw" : 0};
    if (element.rotation === undefined) {
        cube.pivot = {"x": 0, "y": 0, "z": 0};
    } else {
        cube.pivot = {"x": element.rotation.origin[0], "y": element.rotation.origin[1], "z": element.rotation.origin[2]};
        switch (element.rotation.axis) {
            case "x": cube.rotation.roll = element.rotation.angle; break;
            case "y": cube.rotation.yaw = element.rotation.angle; break;
            case "z": cube.rotation.pitch = element.rotation.angle; break;
        };
    }*/
    cube.position = {"x": element.from[0], "y": element.from[1], "z": element.from[2]};
    cube.dimensions = {"w" : element.to[0]-element.from[0], "h" : element.to[1]-element.from[1], "d" : element.to[2]-element.from[2]};
    converted.cubes.push(cube);
});

function processGroup(group) {
    if (typeof(group) == "number") {return;}
    delete group.color;
    group.pivot = {"x" : group.origin[0], "y" : group.origin[1], "z" : group.origin[2]}
    group.children.forEach(processGroup);
}

model.groups.forEach(function(group, key, array) {
    processGroup(group)
    converted.groups.push(group);
});

setTimeout(function() {
    fs.writeFileSync(`${outputDir}\\${filename.slice(filename.lastIndexOf("\\"), filename.lastIndexOf("."))}.json`, JSON.stringify(converted, undefined, 4));
}, Object.keys(model.elements).length * 10);