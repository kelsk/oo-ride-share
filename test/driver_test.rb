require_relative 'test_helper'
require_relative '../lib/trip_dispatcher'

describe "Driver class" do
  describe "Driver instantiation" do
    before do
      @driver = RideShare::Driver.new(
      id: 54,
      name: "Test Driver",
      vin: "12345678901234567",
      status: :AVAILABLE
      )
    end
    
    it "is an instance of Driver" do
      expect(@driver).must_be_kind_of RideShare::Driver
    end
    
    it "throws an argument error with a bad VIN" do
      expect { RideShare::Driver.new(id: 0, name: "George", vin: "33133313331333133") }.must_raise ArgumentError
    end
    
    it "throws an argument error with a bad VIN value" do
      expect { RideShare::Driver.new(id: 100, name: "George", vin: "") }.must_raise ArgumentError
      expect { RideShare::Driver.new(id: 100, name: "George", vin: "33133313331333133extranums") }.must_raise ArgumentError
    end
    
    it "has a default status of :AVAILABLE" do
      expect(RideShare::Driver.new(id: 100, name: "George", vin: "12345678901234567").status).must_equal :AVAILABLE
    end
    
    it "sets driven trips to an empty array if not provided" do
      expect(@driver.trips).must_be_kind_of Array
      expect(@driver.trips.length).must_equal 0
    end
    
    it "is set up for specific attributes and data types" do
      [:id, :name, :vin, :status, :trips].each do |prop|
        expect(@driver).must_respond_to prop
      end
      
      expect(@driver.id).must_be_kind_of Integer
      expect(@driver.name).must_be_kind_of String
      expect(@driver.vin).must_be_kind_of String
      expect(@driver.status).must_be_kind_of Symbol
    end
  end
  
  describe "add_trip method" do
    before do
      pass = RideShare::Passenger.new(
      id: 1,
      name: "Test Passenger",
      phone_number: "412-432-7640"
      )
      @driver = RideShare::Driver.new(
      id: 3,
      name: "Test Driver",
      vin: "12345678912345678"
      )
      @trip = RideShare::Trip.new(
      id: 8,
      driver: @driver,
      passenger: pass,
      start_time: Time.parse("2016-08-08"),
      end_time: Time.parse("2018-08-09"),
      rating: 5
      )
    end
    
    it "adds the trip" do
      expect(@driver.trips).wont_include @trip
      previous = @driver.trips.length
      
      @driver.add_trip(@trip)
      
      expect(@driver.trips).must_include @trip
      expect(@driver.trips.length).must_equal previous + 1
    end
  end
  
  describe "average_rating method" do
    before do
      @driver = RideShare::Driver.new(
      id: 54,
      name: "Rogers Bartell IV",
      vin: "1C9EVBRM0YBC564DZ"
      )
      trip = RideShare::Trip.new(
      id: 8,
      driver: @driver,
      passenger_id: 3,
      start_time: Time.parse("2016-08-08"),
      end_time: Time.parse("2016-08-08"),
      rating: 5
      )
      @driver.add_trip(trip)
    end
    
    it "returns a float" do
      expect(@driver.average_rating).must_be_kind_of Float
    end
    
    it "returns a float within range of 1.0 to 5.0" do
      average = @driver.average_rating
      expect(average).must_be :>=, 1.0
      expect(average).must_be :<=, 5.0
    end
    
    it "returns ArgumentError if driver has no rating" do
      driver = RideShare::Driver.new(
      id: 54,
      name: "Rogers Bartell IV",
      vin: "1C9EVBRM0YBC564DZ"
      )
      expect{driver.average_rating}.must_raise ArgumentError
    end
    
    it "correctly calculates the average rating" do
      trip2 = RideShare::Trip.new(
      id: 8,
      driver: @driver,
      passenger_id: 3,
      start_time: Time.parse("2016-08-08"),
      end_time: Time.parse("2016-08-09"),
      rating: 1
      )
      @driver.add_trip(trip2)
      
      expect(@driver.average_rating).must_be_close_to (5.0 + 1.0) / 2.0, 0.01
    end
    
    it "omits in progress trips from average rating calculation" do
      td = RideShare::TripDispatcher.new(directory: './support')
      new_trip = td.request_trip(7)

      expect(td.drivers[1].average_rating).must_be_kind_of Float
    end     
  end
  
  describe "total_revenue" do
    # You add tests for the total_revenue method
    it "raises ArgumentError if no driven trips" do
      driver = RideShare::Driver.new(
        id: 54,
        name: "Rogers Bartell IV",
        vin: "1C9EVBRM0YBC564DZ"
      )

      expect {driver.total_revenue}.must_raise ArgumentError
    end
    
    it "correctly calculates the total revenue" do
      driver = RideShare::Driver.new(
        id: 54,
        name: "Rogers Bartell IV",
        vin: "1C9EVBRM0YBC564DZ"
      )
      trip1 = RideShare::Trip.new(
        id: 8,
        driver: driver,
        passenger_id: 3,
        start_time: Time.parse("2016-08-08"),
        end_time: Time.parse("2016-08-09"),
        cost: 32,
        rating: 1      
      )

      trip2 = RideShare::Trip.new(
        id: 9,
        driver: driver,
        passenger_id: 5,
        start_time: Time.parse("2016-08-08"),
        end_time: Time.parse("2016-08-09"),
        cost: 20,
        rating: 1      
      )

      driver.add_trip(trip2)
      driver.add_trip(trip1)
      
      expect(driver.total_revenue).must_equal 38.96
    end
    
    it "total_revenue calculation does not include in progress trips" do 
      td = RideShare::TripDispatcher.new
      driver = td.drivers[0]
      
      old_trip1 = RideShare::Trip.new(
        id: 8,
        driver: driver,
        passenger_id: 3,
        start_time: Time.parse("2016-08-08"),
        end_time: Time.parse("2016-08-09"),
        cost: 32,
        rating: 1
      )
      
      old_trip2 = RideShare::Trip.new(
        id: 9,
        driver: driver,
        passenger_id: 5,
        start_time: Time.parse("2016-08-08"),
        end_time: Time.parse("2016-08-09"),
        cost: 20,
        rating: 1      
      )
      
      driver.add_trip(old_trip1)
      driver.add_trip(old_trip2)
      
      new_trip = td.request_trip(7)
      
      expect(td.drivers[0].total_revenue).must_be_kind_of Float
    end 
  end
end
