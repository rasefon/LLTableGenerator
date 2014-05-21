require 'set'

# 'nil' and '$' are predefined terminal token, 'nil' means empty action and '$' is the end flag of parsing.

$start_lside_rule = ""
$token_list = Set.new
$gram_list = Hash.new
$first_set = Hash.new
$follow_set = Hash.new

def construct_table_model(rule_file_name)
   lines = IO.readlines(rule_file_name) 
   lines = lines.map { |l| l.chomp }
   token_def_phase = false
   rule_def_phase = false
   # temporarily record left side tokens and right tokens as string.
   lines.each do |line|
      # skip comment
      next if "#" == line[0]
      # Start token define phase.
      if "``" == line
         if !token_def_phase
            token_def_phase = true
         else
            token_def_phase = false
            rule_def_phase = true
         end
         next
      end

      if token_def_phase
         line.split(':')[1].split(',').each { |t| $token_list.add(t.strip) }
      elsif rule_def_phase
         rule = line.split(':').map { |item| item.strip }
         if "$Start" == rule[0]
            $start_lside_rule = rule[1]
         else
            rhs = rule[1].split(',').map { |r| r.strip }
            if $gram_list.has_key?(rule[0])
               # merge right side rule
               $gram_list[rule[0]] = $gram_list[rule[0]] << rhs
            else
               $gram_list[rule[0]] = [] << rhs
            end
         end
      end
   end
end

def construct_first_set()
   #first to add all the terminal and 'nil' into the FIRST set.
   $gram_list.each do |lhs, rhs_arr|
      unless $first_set.has_key?(lhs)
         $first_set[lhs] = Set.new
      end

      rhs_arr.each do |rhs|
         if $token_list.include?(rhs.first) or "nil" == rhs.first
            $first_set[lhs].add(rhs.first)
         end
      end
   end
   # loop computing first set until no new item is added.
   changed = true
   while (changed)
      changed = false
      $gram_list.each do |lhs, rhs_arr|
         rhs_arr.each do |rhs|
            # If the first item of the rhs token is terminal or 'nil', just skip it because the token had already been
            # added in previous loop.
            next if $token_list.include?(rhs.first) or "nil" == rhs.first

            count = 0
            rhs.each do |rhs_term|
               # If 'nil' is contained in FIRST set of rhs_term, skip to the next term.
               if $first_set[rhs_term].include?("nil")
                  count += 1
                  next
               else
                  # merge the FIRST SET of rhs token with the lhs if necessary.
                  $first_set[rhs_term].each do |token|
                     unless $first_set[lhs].include?(token)
                        $first_set[lhs].add(token)
                        changed = true
                     end
                  end
                  break
               end
            end
            # check if all the rhs tokens produce nil, if so add nil to the lhs FIRST set.
            if rhs.size == count
               $first_set[lhs].add("nil")
            end
         end
      end
   end
end

def construct_follow_set
   # Initialize FOLLOW set and add '$' into the FOLLOW set of start tokens.
   $gram_list.each_key do |lhs|
      $follow_set[lhs] = Set.new
      $follow_set[lhs].add("$") if lhs == $start_lside_rule
   end

   changed = true
   while (changed)
      changed = false
      $gram_list.each do |lhs, rhs_arr|
         rhs_arr.each do |rhs|
            rhs.each_index do |i|
               # skip the nil and terminal token.
               next if 'nil' == rhs[i] or $token_list.include?(rhs[i])

               # case 1, the current rhs term is the last one. 
               if (i+1) == rhs.size 
                  # Union the FOLLOW set of the rhs into the current rhs term.
                  $follow_set[lhs].each do |token|
                     unless $follow_set[rhs[i]].include?(token)
                        changed = true
                        $follow_set[rhs[i]].add(token)
                     end
                  end
               else
                  # First union the FIRST set of the follow rhs token into the current rhs token.
                  if "nil" != rhs[i+1]
                     if $token_list.include?(rhs[i+1])
                        unless $follow_set[rhs[i]].include?(rhs[i+1])
                           changed = true
                           $follow_set[rhs[i]].add(rhs[i+1])
                        end
                     else
                        $first_set[rhs[i+1]].each do |token|
                           if !$follow_set[rhs[i]].include?(token) and "nil" != token
                              changed = true
                              $follow_set[rhs[i]].add(token)
                           end
                        end
                     end
                  end
                  # If the follow rhs tokens produces a 'nil' chain, union the FOLLOW set of lhs into the current rhs token.
                  all_nil = true
                  j = i + 1
                  while (j < rhs.size)
                     # If there is any terminal, break.
                     if "nil" == rhs[j] or $token_list.include?(rhs[j])
                        all_nil = false
                        break
                     end

                     unless $first_set[rhs[j]].include?("nil")
                        all_nil = false
                        break
                     end
                     j += 1
                  end
                  if all_nil
                     $follow_set[lhs].each do |token|
                        unless $follow_set[rhs[i]].include?(token)
                           changed = true
                           $follow_set[rhs[i]].add(token)
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

construct_table_model(ARGV[0])
construct_first_set
construct_follow_set

#puts $start_lside_rule
#puts "" 
#puts $gram_list 
#puts ""
puts "FIRST SET: #{$first_set}"
puts ""
puts "FOLLOW SET: #{$follow_set}"
puts ""

