#!/usr/bin/env ruby
#
# Converts FDX cookbook files to melarecipe format

require 'nokogiri'
require 'pp'
require 'slugify'
require 'json'
require 'zip'
pp ARGV

if ARGV.length != 2
  puts "Usage: "
  puts "  fdx2mela <cookbook.fdx> <output_dir>"
  puts ""
  puts "Invalid number of arguments"
  puts ""
end

file   = ARGV.shift
outdir = ARGV.shift

if ! File.exists? file
  puts "Can't find #{file}"
  puts ""
  exit exit 1
end

if (File.exists? outdir) && (! File.directory? outdir )
  puts "#{outdir} is not a directory"
  puts ""
  exit 1
end
  
if ! File.directory? outdir
  puts "Creating directory #{outdir}"
  Dir.mkdir outdir
end

puts "About to parse #{file} into recipes in directory #{outdir}"

doc = File.open("cookbooks.fdx") { |f| Nokogiri::XML(f) }

cookbooks  = {}
categories = {}

doc.css( "Cookbooks Cookbook" ).each_with_index do |cc,i|
  cookbooks[ cc["ID"].to_i ] = cc["Name"]
end

doc.css( "CookbookChapters CookbookChapter" ).each_with_index do |cc,i|
  categories[ cc["ID"].to_i ] = cc["Name"]
end

doc.css( "Recipes Recipe" ).each do |r|
  recipe = {
    id: "",
    title: "",
    ingredients: "",
    instructions: "",
    notes: "",
    categories: [],
    favor: false,
    wantToCook: false,
    images: []
  }


  recipe[:id] = r["Name"].strip.slugify
  recipe[:title] = r["Name"].strip

  # ingredients
  
  ingredients = []
  
  r.css( "RecipeIngredient" ).each do |ri|
    isHeading = (ri["Heading"] == "Y" )

    if isHeading
      line = "#" + "#{ri['Ingredient']}"
    else
      line = "#{ri['Quantity']} #{ri['Unit']} #{ri['Ingredient']}"
    end

    ingredients << line
    
  end

  # instructions
  
  instructions = []
  
  r.css( "RecipeProcedure" ).each do |rp|
    isHeading = (rp["Heading"] == "Y" )

    if isHeading
      line = "#" + rp.css("ProcedureText").text
    else
      line = rp.css("ProcedureText").text
    end

    instructions << line
    
  end
  
  notes = []
  
  r.css( "RecipeAuthorNote" ).each do |ran|
    notes << ran.text
  end

  recipe[:ingredients] = ingredients.join "\n"
  recipe[:instructions] = instructions.join "\n"
  recipe[:notes] = notes.join "\n"

  recipe[:categories] << cookbooks[ r["CookbookID"].to_i ]
  recipe[:categories] << categories[ r["CookbookChapterID"].to_i ]
  
  outfile = "#{outdir}/#{recipe[:id]}.melarecipe"
  
  File.open( outfile, "w" ) do |of|
    puts "Writing #{recipe[:title]} to #{outfile}"
    of.puts recipe.to_json
  end
  
end

