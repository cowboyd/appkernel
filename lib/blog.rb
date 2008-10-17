
class Post < AppKernel::Command
	
	uses Persistence
	
	option :author, :type => Person, :required => true	
	option :subject, :type => String, :required => true
	option :date, :type => Date, :default => proc {Date.today}
	option :content, :type => String, :required => true
	
	validate {
		@author.must exist
		@date.must_be greaterthan(Date.today)
  }
	
	whenexecuted do
		p = Post.new :author => @author, :subject => @subject, :date => @date, :content => @content
		@persistence.save(p)
		return p
  end
end


#Post -author cote -subject "you're an asshole" content => "Charles is a major asshole"