require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

before do
  @content_table = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").each_with_index.map do |line, index|
      "<p id=paragraph#{index}>#{line}</p>"
    end.join
  end

  def highlight(text, term)
    text.gsub(term, %(<strong>#{term}</strong>))
  end
end

not_found do
  redirect "/"
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @content_table[number - 1]

  redirect "/" unless (1..@content_table.size).cover? number

  @title = "Chapter #{number}: #{chapter_name}"

  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

def read_each_chapter
  @content_table.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

def query_matches_chapter(query)
  results = []

  return results unless query

  read_each_chapter do |number, name, contents|
    matches = {}
    contents.split("\n\n").each_with_index do |paragraph, index|
      matches[index] = paragraph if paragraph.include?(query)
    end
    results << { number: number, name: name, paragraph: matches } if matches.any?
  end

  results
end

get "/search" do
  @results = query_matches_chapter(params[:query])
  erb :search
end
