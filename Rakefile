task :default => :update

# Temporarily switch to the master branch.
def switch_master
  sh 'git stash'
  sh 'git checkout master'
  ret = yield if block_given?
  sh 'git checkout gh-pages'
  sh 'git stash pop' rescue nil
  ret
end

# Generate the API docs.
def generate_api
  sh 'rake api OUTPUT_DIR=api_new'
end

# Overwrite the existing API docs.
def overwrite_api
  sh 'rm -rf api'
  sh 'mv api_new api'
end

# Fetch contents of Markdown doc files.
def fetch_docs
  Dir['doc/*.markdown'].inject({}) do |m, file|
    m[file] = File.read(file)
    m
  end
end

# Generate the HTML docs.
def generate_docs(docs)
  require 'erb'
  require 'rdiscount'
  layout = ERB.new(File.read('layout.html.erb'), 0, '%<>')
  docs.each do |file, source|
    content = Markdown.new(source, :smart).to_html
    output = layout.result(binding)
    File.open(File.basename(file, '.markdown') + '.html', 'w') do |f|
      f.write(output)
    end
  end
end

desc 'Update API docs'
task :api do
  switch_master { generate_api }
  overwrite_api
end

desc 'Update HTML docs'
task :doc do
  docs = switch_master { fetch_docs }
  generate_docs(docs)
end

desc 'Update the entire site'
task :update do
  docs = switch_master do
    generate_api
    fetch_docs
  end
  overwrite_api
  generate_docs(docs)
end
