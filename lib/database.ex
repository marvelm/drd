use Amnesia

defdatabase Database do
  deftable User, [:id,
                  :name,
                  :last_message,
                  :latitude,
                  :longitude,
                  :subscribed], type: :ordered_set
end
